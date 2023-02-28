# Lab 03

In this lab you are going to install Kubernetes as all-in-one single-node deployment and access it.

Open the terminal and run the following commands listed below.

## Install Kubernetes

1. Get the root privileges and launch the script.

    ```sh
    sudo su -
    ```

2. Install an all-in-one single control-plane Kubernetes cluster.
    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/k8s-no-cni-install.sh | sh
    ```

    The script prepares the host by installing and configuring prerequisites (e.g. enabling IPv4 forwarding and letting iptables see bridged traffic), a container runtime (`containerd` and `runc`), `kubeadm`, `kubelet` and `kubectl`.
    Then it lanches the `kubeadm init` command to bootstrap the control-plane Kubernetes node.

3. Exit the root shell.

    ```sh
    exit
    ```

4. Enable kubectl shell autompletion in the current session.

    ```sh
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    source ~/.bashrc
    ```

5. Once the installation is completed, you can connect to the API server and check the nodes status.

    ```sh
    kubectl get node
    ```

    You should see the following message:

    ```plaintext
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

    This is due to the lack of a kubeconfig file. The `kubectl` command-line tool uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster.
    By default, `kubectl` looks for the `~/.kube/config` file. You can specify other kubeconfig files by setting the `KUBECONFIG` environment variable. 
    
6. During cluster creation, kubeadm signs the certificate in the `/etc/kubernetes/admin.conf` to have `Subject: O = system:masters, CN = kubernetes-admin`. Copy it in `~/.kube/config`:

    ```sh
    sudo cp /etc/kubernetes/admin.conf ~/.kube/config
    ```

7. Try to run `kubectl get node` again. The output is simlar to this:

    ```plaintext
    NAME    STATUS     ROLES           AGE   VERSION
    cp-01   NotReady   control-plane   30s   v1.25.6
    ```

    As you can see, the node is in the `NotReady` status. From the end of the `kubeadm init` output you may have seen the statement:

    ```plaintext
    You should now deploy a pod network to the cluster
    ```

## Generate a kubeconfig file for admin access within the default namespace

 The `admin.conf` kubeconfig file uses a signed certificate for `Subject: O = system:masters, CN = kubernetes-admin`. Kubernetes come with a ClusterRoleBinding named `cluster-admin` that binds the `cluster-admin` ClusterRole with the `system:masters` group. 

 1. Let's inspect the built-in `cluster-admin` ClusterRole.

    ```sh
    kubectl get clusterrole cluster-admin -o yaml
    ```

2. Verify the above CluserRole is bound to the `system:masters` group using the built-in `cluster-admin` ClusterRoleBinding.

    ```sh
    kubectl get clusterrolebinding cluster-admin -o yaml
    ```

 3. `system:masters` is a break-glass, super user group that bypasses the authorization layer (e.g. RBAC). Sharing the `admin.conf` with additional users is **not recommended**! Instead, you can use the `kubeadm kubeconfig user` command to generate kubeconfig files for additional users. Kubernetes comes with other ClusterRoles, including the `admin` one, which allows admin access. This role is intended to be granted within a namespace using a **RoleBinding**. Let's create a RoleBinding resource which binds the `admin` ClusterRole to the group `admin`.

    ```sh
    kubectl create rolebinding admin --clusterrole=admin --group=admin
    ```

    **Note**: This RoleBinding will be created in the `default` namespace. Thus, user belonging to `admin` group will have admin access only to this namespace.

4. Create a kubeconfig file for user `ksp-user` belonging to the `admin` group.

    ```sh
    kubeadm kubeconfig user --config <(kubectl get cm kubeadm-config -n kube-system -o=jsonpath="{.data.ClusterConfiguration}") --org admin --client-name ksp-user > ksp-user-config.yaml
    ```

5. View the generated kubeconfig file.

    ```sh
    cat ksp-user-config.yaml
    ```

    This kubeconfig file can be shared with the right user and will become its `~/.kube/config` file.

## Next

[Lab 04](./lab04.md)