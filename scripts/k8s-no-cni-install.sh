#!/bin/sh

K8S_VERSION="1.25.6"
RUNC_VERSION="1.1.4"
CONTAINERD_VERSION="1.6.16"
CLI_ARCH="amd64"

if [ ! -z "$1" ]; then
  K8S_VERSION="$1"
fi

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Installing and configure prerequisites

# Disabling swap
sudo sed -i 's/\/swap/#\/swap/' /etc/fstab
sudo swapoff -a

# Add modules permanently
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf > /dev/null
overlay
br_netfilter
EOF

# Enable modules
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf > /dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply kernel params without reboot
sudo sysctl --system

# Installing the container runtime

# Configure containerd
curl -sLO https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-$CLI_ARCH.tar.gz
sudo tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-$CLI_ARCH.tar.gz
rm containerd-$CONTAINERD_VERSION-linux-$CLI_ARCH.tar.gz
sudo mkdir -p /usr/local/lib/systemd/system
curl -sL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service | sudo tee /usr/local/lib/systemd/system/containerd.service > /dev/null

if [ ! -d /etc/containerd ]; then sudo mkdir /etc/containerd; fi
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install runc
curl -sLO https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.$CLI_ARCH
sudo install -m 755 runc.$CLI_ARCH /usr/local/bin/runc
rm runc.$CLI_ARCH

# Configure crictl
# cat <<EOF | sudo tee /etc/crictl.yaml > /dev/null
# runtime-endpoint: unix:///run/containerd/containerd.sock
# image-endpoint: unix:///run/containerd/containerd.sock
# timeout: 10
# EOF


# Installing kubeadm, kubelet and kubectl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=$K8S_VERSION-00 kubeadm=$K8S_VERSION-00 kubectl=$K8S_VERSION-00
sudo apt-mark hold kubelet kubeadm kubectl


# Init control-plane
cat <<EOF | sudo tee ~/kubeadm-config.yaml > /dev/null
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

# Init the control plane node
sudo kubeadm init --config ~/kubeadm-config.yaml

# Copy the admin config file to the default kubectl directory
if [ ! -d ~/.kube ]; then mkdir ~/.kube; fi
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# kubectl auto-completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source ~/.bashrc