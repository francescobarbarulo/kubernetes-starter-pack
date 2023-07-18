# Kubernetes installation

## Prepare a kubernetes node

1. Disable swap

2. [Install and configure prerequisites](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites)

  ```sh
  curl https://github.com/francescobarbarulo/kubernetes-starter-pack/blob/main/scripts/network-prerequisites.sh | sh
  ```

3. Export variables for tool versions

  ```sh
  export ARCH=amd64
  export RUNC_VERSION=1.1.7
  export CONTAINERD_VERSION=1.7.2
  export CRICTL_VERSION=1.27.1
  export K8S_VERSION=1.27.3
  ```

4. Install a container runtime (containerd and runc), kubeadm and kubelet

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/node-prep.sh | sh
  ```


## Initialiaze the first control plane node

1. Create the configuration file for kubeadm

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/kubeadm-config.yaml
  ```

2. Boostrap the Kubernetes control-plane components

  ```sh
  kubeadm init --config kubeadm-config.yaml [--upload-certs]
  ```


## Install kubectl on local machine

1. Set some environment variables in order to download the correct version of `kubectl`.

  ```sh
  export ARCH=amd64
  export K8S_VERSION=1.27.3
  ``` 

2. Install `kubectl`.

  ```sh
  curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubectl
  sudo install -m 755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
  ```

3. Enable kubectl shell autompletion in the current session.

  ```sh
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  source ~/.bashrc
  ```

4. Copy kubeconfig file from the control-plane node

  ```sh
  mkdir -p $HOME/.kube
  scp root@<cp-ip>:/etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```