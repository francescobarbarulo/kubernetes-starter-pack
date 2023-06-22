#!/bin/sh

# Destory lab instances
INSTANCES="dev registry k8s-cp-01 k8s-w-01"

for instance in $INSTANCES

do
  lxc stop $instance
  lxc delete $instance
done