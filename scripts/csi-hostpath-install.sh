#!/bin/sh

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-provisioner/v3.4.0/deploy/kubernetes/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-attacher/v4.2.0/deploy/kubernetes/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-resizer/v1.7.0/deploy/kubernetes/rbac.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-host-path/master/deploy/kubernetes-1.24/hostpath/csi-hostpath-driverinfo.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-host-path/master/deploy/kubernetes-1.24/hostpath/csi-hostpath-plugin.yaml