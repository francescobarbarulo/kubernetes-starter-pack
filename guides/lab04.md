# Lab 04

In this lab you are going to create a Kubernetes cluster with `kubeadm`, starting from the initialization of the control-plane node.


## Initialize the control-plane node

Open a shell in the `k8s-cp-01` environment.

1. Set some environment variables.

    ```sh
    export K8S_VERSION=1.25.6
    export ARCH=amd64
    export REGISTRY=172.30.10.11
    ```

1. Prepare the host by installing and configuring prerequisites (e.g. enabling IPv4 forwarding and letting iptables see bridged traffic), a container runtime (`containerd` and `runc`), `kubeadm` and `kubelet`.
    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lxd/node-prep.sh | sh
    ```

2. Create the configuration file for kubeadm.

    ```sh
    cat <<EOF | tee ~/kubeadm-config.yaml > /dev/null
    kind: InitConfiguration
    apiVersion: kubeadm.k8s.io/v1beta3
    nodeRegistration:
        criSocket: "unix:///run/containerd/containerd.sock"
    ---
    kind: ClusterConfiguration
    apiVersion: kubeadm.k8s.io/v1beta3
    kubernetesVersion: v$K8S_VERSION
    clusterName: "kubernetes"
    networking:
        dnsDomain: "cluster.local"
        serviceSubnet: "10.96.0.0/12"
    ---
    kind: KubeletConfiguration
    apiVersion: kubelet.config.k8s.io/v1beta1
    cgroupDriver: "systemd"
    EOF
    ```

3. Boostrap the Kubernetes control-plane components.

    ```sh
    kubeadm init --config kubeadm-config.yaml
    ```

    If everything works fine, the output is similar to this:

    ```plaintext
    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    Alternatively, if you are the root user, you can run:

    export KUBECONFIG=/etc/kubernetes/admin.conf

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
        https://kubernetes.io/docs/concepts/cluster-administration/addons/

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 172.30.10.252:6443 --token 6eqtaq.y2froj5ailc5jmsw \
	    --discovery-token-ca-cert-hash sha256:15e198e09831fe77c4f727e214f166fd66c723bc69c9bf4c6bbc6788c6d8b4d4
    ```

## Access the Kubernetes cluster with kubectl

Open a shell on the `student` machine.

1. Set again the environment variables.

    ```sh
    export K8S_VERSION=1.25.6
    export ARCH=amd64
    ``` 

1. Install `kubectl`.

    ```sh
    curl -sLO https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/${ARCH}/kubectl
    sudo install -m 755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
    ```

2. Enable kubectl shell autompletion in the current session.

    ```sh
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    source ~/.bashrc
    ```

5. Try to connect to the API server and check the nodes status.

    ```sh
    kubectl get node
    ```

    You should see the following message:

    ```plaintext
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

    This is due to the lack of a kubeconfig file. The `kubectl` command-line tool uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster.
    By default, `kubectl` looks for the `~/.kube/config` file. You can specify other kubeconfig files by setting the `KUBECONFIG` environment variable. 
    
6. During cluster creation, kubeadm signs the certificate in the `/etc/kubernetes/admin.conf` to have `Subject: O = system:masters, CN = kubernetes-admin`. Copy it in `~/.kube/config` from `k8s-cp-01` environment:

    ```sh
    mkdir ~/.kube && lxc file pull k8s-cp-01/etc/kubernetes/admin.conf ~/.kube/config
    ```

7. Try to run `kubectl get node` again. The output is simlar to this:

    ```plaintext
    NAME        STATUS     ROLES           AGE   VERSION
    k8s-cp-01   NotReady   control-plane   1m   v1.25.6
    ```

    As you see, the node is in the `NotReady` status. From the end of the `kubeadm init` output you may have seen the statement:

    ```plaintext
    You should now deploy a pod network to the cluster
    ```

    This means that to make the node `Ready` you need to install a CNI plugin responsible for managing the networking resources for the Kubernetes cluster.
    However you can interact with the up and running API server with `kubectl`.

## Kubernetes RBAC authorization management

Kubernetes uses the Role-based access control (RBAC) method to regulate access to the cluster.
At the moment, you are able to access the API server because you are using the `admin.conf` kubeconfig file that uses a signed certificate for `Subject: O = system:masters, CN = kubernetes-admin`. Kubernetes come with a ClusterRoleBinding named `cluster-admin` that binds the `cluster-admin` ClusterRole with the `system:masters` group. 

1. Let's inspect the built-in `cluster-admin` ClusterRole.

    ```sh
    kubectl get clusterrole cluster-admin -o yaml
    ```

    As you see, it gives full access (`*` in `verbs`) to any resource (`*` in `resources`).

2. Verify the above ClusterRole is bound to the `system:masters` group using the built-in `cluster-admin` ClusterRoleBinding.

    ```sh
    kubectl get clusterrolebinding cluster-admin -o yaml
    ```

 3. `system:masters` is a break-glass, super user group that bypasses the authorization layer (e.g. RBAC). Sharing the `admin.conf` with additional users is **not recommended**! Instead, you can use tools like `openssl` or [`kubeadm kubeconfig user`](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#kubeconfig-additional-users) command to generate certificates and kubeconfig files for additional users. Kubernetes comes with other ClusterRoles, including the `admin` one, which allows admin access. This role is intended to be granted within a namespace using a **RoleBinding**. View the `admin` ClusterRole.

    ```sh
    kubectl get clusterrole admin -o yaml
    ```
 
 4. Let's bind the `admin` ClusterRole to the group `admin` creating a RoleBinding.

    ```sh
    kubectl create rolebinding admin --clusterrole=admin --group=admin
    ```

    **Note**: This RoleBinding will be created in the `default` namespace. Thus, user belonging to `admin` group will have admin access only to the `default` namespace.

Assume you need to assign admin privileges to your developer `jane` in the `default` namespace. You need to create a signed certificate for `Subject: O = admin, CN = jane`. To do this you need the root CA certificate of the Kubernetes instance.

1. Copy the key and the certificate from the control-plane node to the `student` machine.

    ```sh
    lxc file pull k8s-cp-01/etc/kubernetes/pki/ca.{key,crt} .
    ```

2. Generate `jane` keys.

    ```sh
    openssl genrsa -out jane.key 2048
    ```

3. Generate a *Certificate Signing Request*.

    ```sh
    openssl req -new -key jane.key -subj "/CN=jane/O=admin" -out jane.csr
    ```

4. Create and sign the certificate with the Kubernetes CA key.

    ```sh
    openssl x509 -req -in jane.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out jane.crt
    ```

5. Set the `API_SERVER` environment variable.

    ```sh
    export API_SERVER=172.30.10.20
    ```

6. Create a kubeconfig file for user `jane`.

    ```sh
    export CA_CRT=$(cat ca.crt | base64 -w 0)
    export JANE_CRT=$(cat jane.crt | base64 -w 0)
    export JANE_KEY=$(cat jane.key | base64 -w 0)
    cat <<EOF | tee jane-config > /dev/null
    apiVersion: v1
    kind: Config
    current-context: jane@kubernetes
    clusters:
    - name: kubernetes
      cluster:
        certificate-authority-data: ${CA_CRT}
        server: https://${API_SERVER}:6443
    contexts:
    - name: jane@kubernetes
      context:
        cluster: kubernetes
        user: jane
        namespace: default
    users:
    - name: jane
      user:
        client-certificate-data: ${JANE_CRT}
        client-key-data: ${JANE_KEY}
    EOF
    ```

5. Set the `KUBECONFIG` environment variable to the just created kubeconfig file.

    ```sh
    export KUBECONFIG=jane-config
    ```

6. View the generated kubeconfig file.

    ```sh
    kubectl config view
    ```

7. Verify `jane` can create namespaced resources (e.g. Roles):

    ```sh
    kubectl auth can-i create roles
    ```

    The output is similar to this:

    ```plaintext
    yes
    ```

    But `jane` can not list cluster scoped resources (e.g. Nodes):

    ```sh
    kubectl auth can-i get nodes
    ```
  
    The output is similar to this:

    ```plaintext
    Warning: resource 'nodes' is not namespace scoped
    no
    ```

8. Unset the `KUBECONFIG` environment variable.

    ```sh
    unset KUBECONFIG
    ```

## Next

[Lab 05](./lab05.md)