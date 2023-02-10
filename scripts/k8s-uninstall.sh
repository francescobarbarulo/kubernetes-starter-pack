#!/bin/sh

# Clean up the node
sudo kubeadm reset

# Remove cni setup
sudo rm -r /etc/cni/net.d

# FLush iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Remove containerd
sudo systemctl stop containerd
sudo rm -rf /usr/local/lib/systemd
sudo rm /usr/local/bin/*
sudo systemctl daemon-reload

# Remove kubeadm, kubelet, kubectl
sudo apt-get purge kubeadm kubelet kubectl -y --allow-change-held-packages

sudo apt-get autoremove -y