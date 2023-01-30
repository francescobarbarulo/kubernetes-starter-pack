#!/bin/sh

# Uninstall docker
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io
sudo rm /etc/apt/keyrings/docker.gpg

# Remove user from docker group and remove the group
sudo deluser $USER docker
sudo delgroup docker

# Reset iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT