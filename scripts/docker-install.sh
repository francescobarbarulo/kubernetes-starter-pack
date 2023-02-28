#!/bin/sh

# Install using the repository
# (https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)


# Set up the reposiroty
# 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS
apt-get update

apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 2. Add Docker’s official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Use the following command to set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


# Install Docker Engine

# 1. Update the apt package index
apt-get update

# 2. Install Docker Engine and containerd
apt-get install -y docker-ce docker-ce-cli containerd.io