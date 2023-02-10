# Lab 03

In this lab you are going to install Kubernetes as all-in-one single-node deployment.

Open the terminal and run the following commands listed below.

## Install Kubernetes

1. Install a single control-plane Kubernetes cluster.

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/k8s-no-cni-install.sh | sh
    ```

    The script prepares the host by installing and configure prerequisites (forwarding IPv4 and letting iptables see bridged traffic), a container runtime (`containerd` and `runc`), `kubeadm`, `kubelet` and `kubectl`.
    Then it lanches the `kubeadm init` command to bootstrap the control-plane Kubernetes node.

2. Once the installation is completed, check you can connect to the API server.

    ```sh
    kubectl get node
    ```

    You should see the following output:

    ```plaintext
    NAME    STATUS     ROLES           AGE   VERSION
    cp-01   NotReady   control-plane   30s   v1.25.6
    ```

    As you can see, the node is in the `NotReady` status. From the end of the `kubeadm init` output you may have seen the statement:

    ```plaintext
    You should now deploy a pod network to the cluster
    ```

    Kubernetes is not opinionated, it lets you choose your own CNI solution. Until a CNI plugin is installed the cluster will be inoperable. List the running Pods in all namespaces (`-A`):

    ```sh
    kubectl get pod -A
    ```

    You should see the CoreDNS Pods not ready and they will not start up before a network is installed.

3. Install [Cilium](https://cilium.io/) as our CNI plugin.

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/cni-cilium-install.sh | sh
    ```

    The script will deploy two Pods:
    * `cilium-operator`
    * `cilium-agent`

    The Operator is responsible for managing duties in the cluster which should logically be handled once for the entire cluster.
    The Agent runs on each node in the cluster and configures Pod network interfaces as workloads are created and deleted.

    Great! Now if we take a look at the cluster it should be in the `Ready` status.

    Let's take a look at the running Pods too by running `kubectl get pod -n kube-system`. CoreDNS and Cilium pods are now running.

    Note that the Pods we have so far are part of the Kubernetes system itself, therefor they run in a namespace called `kube-system`.




