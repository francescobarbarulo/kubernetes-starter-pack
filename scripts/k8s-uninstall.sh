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