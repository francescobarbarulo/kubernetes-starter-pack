#!/bin/sh

# Init control-plane
cat <<EOF | tee ~/kubeadm-config.yaml > /dev/null
kind: InitConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
nodeRegistration:
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

echo "Init Control Plane"
kubeadm init --config ~/kubeadm-config.yaml