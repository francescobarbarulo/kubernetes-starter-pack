# Kubernetes installation

## Prepare a kubernetes node

1. Update OS and install required tools

  ```sh
  sudo apt install ebtables ethtool socat conntrack iptables
  ```

2. Disable swap

  ```sh
  swapoff -a
  sed -i 's/\/swap/#\/swap/' /etc/fstab
  ```

3. [Install and configure prerequisites](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites)

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/network-prerequisites.sh | sh
  ```

4. Export variables for tool versions

  ```sh
  export ARCH=amd64
  export RUNC_VERSION=1.1.7
  export CONTAINERD_VERSION=1.7.2
  export CRICTL_VERSION=1.27.1
  export K8S_VERSION=1.27.3
  ```

5. Install a container runtime (containerd and runc), kubeadm and kubelet

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/node-prep.sh | sh
  ```


## Initialiaze the first control plane node

1. Create the configuration file for kubeadm

  ```sh
  curl -sLO https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/kubeadm-config.yaml
  ```

2. Boostrap the Kubernetes control-plane components

  ```sh
  kubeadm init --config kubeadm-config.yaml [--upload-certs] [--skip-phases=addon/kube-proxy]
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

5. Approve kubelet CSRs

  ```sh
  kubectl get csr -o name | xargs -n 1 kubectl certificate approve
  ```

## Install Cilium as CNI plugin

1. Install Cilium CLI on local machine

  ```sh
  CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
  CLI_ARCH="amd64"

  curl -sSL --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
  rm cilium-linux-${CLI_ARCH}.tar.gz cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  ```

2. Install Cilium CNI plugin in the cluster

  ```sh
  # Cluster scope (default)
  POD_CIDR=172.16.0.0/16
  cilium install --helm-set ipam.operator.clusterPoolIPv4PodCIDRList=$POD_CIDR
  # Kubernetes Host scope (podSubnet must be set in ClusterConfiguration)
  cilium install [--version v1.13.4] --helm-set ipam.mode=kubernetes
  ```