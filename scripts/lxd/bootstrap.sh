#!/bin/sh

# Init lxd
cat ./lxd-config | lxd init --preseed

# Create k8s profile
lxc profile list | grep -qo k8s || (lxc profile create k8s && cat ./k8s-profile-config | lxc profile edit k8s)

# Create lab instances
INSTANCES="dev:172.30.10.10 registry:172.30.10.11 nfs:172.30.10.12 k8s-cp-01:172.30.10.20 k8s-w-01:172.30.10.21 k8s-w-02:172.30.10.22"

for instance in $INSTANCES

do
  name=$(echo $instance | cut -d ":" -f 1)
  ipv4_addr=$(echo $instance | cut -d ":" -f 2)
  lxc init images:ubuntu/jammy/cloud $name -d eth0,ipv4.address=$ipv4_addr --profile k8s
  lxc start $name
done

sleep 10

for instance in $INSTANCES

do
  lxc exec $instance -- cloud-init status --wait
  lxc exec $instance -- apt install -y linux-image-$(uname -r) > /dev/null
done

