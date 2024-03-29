#!/bin/sh

RUNC_VERSION="1.1.4"
CONTAINERD_VERSION="1.6.16"
CRICTL_VERSION="1.26.0"
K8S_VERSION="1.25.6"

case $(uname -m) in
  "x86_64") ARCH="amd64" ;;
  "aarch64") ARCH="arm64"   ;;
  *) echo "Architecture not supported"; exit ;;
esac

echo "arch:        $ARCH"
echo "runc:        $RUNC_VERSION"
echo "containerd:  $CONTAINERD_VERSION"
echo "crictl:      $CRICTL_VERSION"
echo "kubernetes:  $K8S_VERSION"


# Check tar, conntrack and socat are installed
# Install dependencies for kubeadm tool
# If you manage to use other Linux distributions you can replace apt-get with their own packege managers
apt-get update && apt-get install -y tar socat conntrack ca-certificates curl

# Disabling swap
echo "Disabling swap"
sed -i 's/\/swap/#\/swap/' /etc/fstab
swapoff -a

# Open required firewall ports
# firewall-cmd --add-port=10250/tcp --permanent # kubelet
# firewall-cmd --reload
systemctl stop firewalld
systemctl disable firewalld


# Forwarding IPv4 and letting iptables see bridged traffic

# Add modules to Linux Kernel
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay       # overlay filesystem
br_netfilter  # enable transparent masquerading
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1 # packets traversing the bridge are sent to iptables for processing
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1 # enable routing
EOF

# Apply sysctl params without reboot
sysctl --system

# Installing the container runtime

# Configure containerd
echo "Installing containerd"
curl -sSLO https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
rm -f containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
mkdir -p /usr/local/lib/systemd/system
curl -sL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service | tee /usr/local/lib/systemd/system/containerd.service > /dev/null

if [ ! -d /etc/containerd ]; then mkdir /etc/containerd; fi
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd

# Install runc
echo "Installing runc"
curl -sLO https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${ARCH}
install -m 755 runc.${ARCH} /usr/local/bin/runc
rm -f runc.${ARCH}

# Install and configure crictl
echo "Installing crictl"
curl -sLO https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz
tar zxvf crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz -C /usr/local/bin
rm -f crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz
cat <<EOF | tee /etc/crictl.yaml > /dev/null
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
EOF

# Installing kubeadm
echo "Installing kubeadm"
curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubeadm
install kubeadm /usr/local/bin/kubeadm
rm -f kubeadm

# Installing kubelet
# NOTE: kubeadm does not create /etc/kubernetes/manifests directory. Make dir by hand
echo "Installing kubelet"
curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubelet
install kubelet /usr/local/bin/kubelet
rm -f kubelet
RELEASE_VERSION="$(curl -s https://api.github.com/repos/kubernetes/release/releases/latest | grep tag_name | sed -E 's/.*"([^"]+)".*/\1/')"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" | tee /usr/local/lib/systemd/system/kubelet.service > /dev/null
mkdir -p /usr/local/lib/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:/usr/local/bin:g" | tee /usr/local/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl enable --now kubelet

# Installing kubectl
echo "Installing kubectl"
curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubectl
install -m 755 kubectl /usr/local/bin/kubectl
rm -f kubectl


# Init control-plane
cat <<EOF | tee ~/kubeadm-config.yaml > /dev/null
kind: InitConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
nodeRegistration:
  name: "cp-01"
  criSocket: "unix:///run/containerd/containerd.sock"
---
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v$K8S_VERSION
clusterName: "kubernetes"
networking:
  dnsDomain: "cluster.local"
  serviceSubnet: "10.96.0.0/12"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: "systemd"
EOF
kubeadm init --config ~/kubeadm-config.yaml