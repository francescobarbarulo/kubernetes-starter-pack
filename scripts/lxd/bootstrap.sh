#!/bin/sh

# Init lxd
cat ./lxd-config | lxd init --preseed

# Create k8s profile
lxc profile list | grep -qo k8s || (lxc profile create k8s && cat ./k8s-profile-config | lxc profile edit k8s)

# Create lab instances
INSTANCES="dev registry k8s-cp-01 k8s-w-01"

for instance in $INSTANCES

do
  lxc init images:ubuntu/jammy/cloud $instance --profile k8s
  lxc start $instance
done

for instance in $INSTANCES

do
  lxc exec $instance -- cloud-init status --wait
  lxc exec $instance -- apt-get install -y linux-image-$(uname -r)
done