#!/bin/sh

PREFIX=scripts/lab

sudo sysctl -w net.netfilter.nf_conntrack_max=$(($(nproc)*65536)) > /dev/null

# Init Incus
cat $PREFIX/incus-config | incus admin init --preseed

# Create k8s profile
incus profile list | grep -qo k8s || (incus profile create k8s && cat $PREFIX/k8s-profile-config | incus profile edit k8s)

# Create lab instances
INSTANCES="dev:172.30.10.10 registry:172.30.10.11 nfs:172.30.10.12 k8s-cp-01:172.30.10.20 k8s-w-01:172.30.10.21 k8s-w-02:172.30.10.22"

for instance in $INSTANCES

do
  name=$(echo $instance | cut -d ":" -f 1)
  ipv4_addr=$(echo $instance | cut -d ":" -f 2)
  incus init images:ubuntu/jammy/cloud $name -d eth0,ipv4.address=$ipv4_addr --profile k8s
  incus start $name
done

for instance in $INSTANCES

do
  name=$(echo $instance | cut -d ":" -f 1)
  incus config device add $name modules disk source=/lib/modules path=/lib/modules
done

