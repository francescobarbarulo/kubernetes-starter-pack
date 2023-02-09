#!/bin/sh

K8S_VERSION="1.25.4"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Configure containerd
sudo apt-get install -y containerd
if [ ! -d /etc/containerd ]; then sudo mkdir /etc/containerd; fi
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Configure crictl
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

# Installing and configure prerequisites

# Disabling swap
sudo sed -i 's/\/swap/#\/swap/' /etc/fstab
sudo swapoff -a

# Add modules permanently
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Enable modules
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply kernel params without reboot
sudo sysctl --system


# Installing kubeadm, kubelet and kubectl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=$K8S_VERSION-00 kubeadm=$K8S_VERSION-00 kubectl=$K8S_VERSION-00
sudo apt-mark hold kubelet kubeadm kubectl


# Init control-plane
cat <<EOF | sudo tee $HOME/kubeadm-config.yaml
kind: InitConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
---
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v$K8S_VERSION
networking:
  serviceSubnet: "10.96.0.0/16"
  # podSubnet: "10.244.0.0/24" # is it mandatory?
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

# Init the control plane node
sudo kubeadm init --config $HOME/kubeadm-config.yaml

# Copy the admin config file to the default kubectl directory
if [ ! -d $HOME/.kube ]; then mkdir $HOME/.kube; fi
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config