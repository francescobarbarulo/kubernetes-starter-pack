#!/bin/sh

# Stop and remove docker socket
sudo systemctl stop docker.socket
sudo rm -rf /var/run/docker.sock

# Uninstall docker
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo apt-get autoremove -y
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf /var/run/docker

# Delete docker repository
sudo rm -rf /etc/apt/keyrings/docker.gpg
sudo rm -rf /etc/apt/sources.list.d/docker.list

# Delete bridge
sudo ip link delete docker0

# Reset iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Remove user from docker group
sudo deluser $USER docker

# Delete docker group
sudo delgroup docker
