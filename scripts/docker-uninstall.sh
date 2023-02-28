#!/bin/sh

# Stop and remove running containers
docker rm -f $(docker ps -aq)
docker volume ls | awk 'NR>1 {print $2}' | xargs -n 1 docker volume rm
docker network ls | awk 'NR>4 {print $1}' | xargs -n 1 docker network rm
docker images | awk 'NR>1 {print $3}' | xargs -n 1 docker rmi

# Stop the docker.service
systemctl stop docker.service

# Stop and remove docker socket
systemctl stop docker.socket
rm -rf /var/run/docker.sock

# Uninstall docker
apt-get purge -y docker-ce docker-ce-cli containerd.io
apt-get autoremove -y
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -rf /var/run/docker

# Delete docker repository
rm -rf /etc/apt/keyrings/docker.gpg
rm -rf /etc/apt/sources.list.d/docker.list

# Delete bridge
ip link delete docker0

# Reset iptables
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Remove user from docker group
deluser $USER docker

# Delete docker group
delgroup docker
