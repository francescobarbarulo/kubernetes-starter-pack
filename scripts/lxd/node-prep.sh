#!/bin/sh

K8S_VERSION="1.25.6"

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

echo "Init Control Plane"
kubeadm init --config ~/kubeadm-config.yaml --ignore-preflight-errors=all