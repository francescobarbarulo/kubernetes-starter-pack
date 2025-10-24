#!/bin/sh

# Destory lab instances
INSTANCES="dev registry nfs k8s-cp-01 k8s-w-01 k8s-w-02 lb"

for instance in $INSTANCES

do
  incus stop $instance
  echo "Removing $instance"
  incus delete $instance
done

if [ -d ~/.kube ]; then rm -r ~/.kube; fi