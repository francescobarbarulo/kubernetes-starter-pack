# Lab 04

In this lab you are going to create a Kubernetes cluster with `kubeadm`, starting from the initialization of the control-plane node.


## Initialize the control-plane node

🖥️ Open a shell in the `k8s-cp-01` environment.

1. Set some environment variables in order to download the right version and configure all the components correctly .

    ```sh
    export ARCH=amd64
    export RUNC_VERSION=1.1.11
    export CONTAINERD_VERSION=1.7.11
    export CRICTL_VERSION=1.29.0
    export K8S_VERSION=1.29.0
    export REGISTRY=172.30.10.11
    ```

2. Prepare the host by installing and configuring prerequisites (e.g. enabling IPv4 forwarding and letting iptables see bridged traffic), a container runtime (`containerd` and `runc`), `kubeadm` and `kubelet`.
    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/node-prep.sh | sh
    ```

3. Create the configuration file for kubeadm.

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

4. Boostrap the Kubernetes control-plane components.

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

🖥️ Open a shell in the `student` machine.

1. Set some environment variables in order to download the correct version of `kubectl`.

    ```sh
    export K8S_VERSION=1.29.0
    export ARCH=amd64
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

4. Try to connect to the API server and check the nodes status.

    ```sh
    kubectl get node
    ```

    You should see the following message:

    ```plaintext
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

    This is due to the lack of a kubeconfig file. The `kubectl` command-line tool uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster.
    By default, `kubectl` looks for the `~/.kube/config` file. You can specify other kubeconfig files by setting the `KUBECONFIG` environment variable. 
    
5. During cluster creation, kubeadm signs the certificate in the `/etc/kubernetes/admin.conf` to have `Subject: O = system:masters, CN = kubernetes-admin`. Copy it into `~/.kube/config` from `k8s-cp-01` environment:

    ```sh
    mkdir ~/.kube && incus file pull k8s-cp-01/etc/kubernetes/admin.conf ~/.kube/config
    ```

6. Try to run `kubectl get node` again. The output is simlar to this:

    ```plaintext
    NAME        STATUS     ROLES           AGE   VERSION
    k8s-cp-01   NotReady   control-plane   1m   v1.25.6
    ```

    As you see, the node is in the `NotReady` status. From the end of the `kubeadm init` output, in the `k8s-cp-01` environment, you may have seen the statement:

    ```plaintext
    You should now deploy a pod network to the cluster
    ```

    This means that to make the node `Ready` you need to install a CNI plugin responsible for managing the networking resources for the Kubernetes cluster.
    However you can interact with the up and running API server with `kubectl`.

## Kubernetes Resources

Kubernetes has a powerful REST-based API. `kubectl` makes API calls on your behalf, responding to typical HTTP verbs (`GET`, `POST`, `DELETE`).
A *resource* is an endpoint in the Kubernetes API.

🖥️ Open a shell in the `student` machine.

1. View all the resources you can manage in a default Kubernetes installation.

    ```sh
    kubectl api-resources
    ```

    > Some of the objects have `SHORTNAMES`, which makes using them on the command line much easier.

    This list can be extended by adding *Custom Resource Definitions* (CRDs), making Kubernetes modular.


## Kubernetes RBAC authorization management

Kubernetes uses the Role-based access control (RBAC) method to regulate access to the cluster.
At the moment, you are able to access the API server because you are using the `admin.conf` kubeconfig file that uses a signed certificate for `Subject: O = system:masters, CN = kubernetes-admin`. Kubernetes come with a ClusterRoleBinding named `cluster-admin` that binds the `cluster-admin` ClusterRole with the `system:masters` group.

🖥️ Open a shell in the `student` machine.

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

## Create a kubeconfig file for a new user

Assume you need to assign admin privileges to your developer `jane` in the `default` namespace. You need to create a signed certificate for `Subject: O = admin, CN = jane`. To do this you need the root CA certificate of the Kubernetes instance.

🖥️ Open a shell in the `student` machine.

1. Copy the key and the certificate from the control-plane node to the `student` machine.

    ```sh
    incus file pull k8s-cp-01/etc/kubernetes/pki/ca.{key,crt} .
    ```

2. Set the `USERNAME` environment variable to use in the next steps.

    ```sh
    export USERNAME=jane
    ```
2. Generate `jane`'s keys.

    ```sh
    openssl genrsa -out $USERNAME.key 2048
    ```

3. Generate a *Certificate Signing Request*.

    ```sh
    openssl req -new -key $USERNAME.key -subj "/CN=$USERNAME/O=admin" -out $USERNAME.csr
    ```

4. Create and sign the certificate with the Kubernetes CA key.

    ```sh
    openssl x509 -req -in $USERNAME.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $USERNAME.crt
    ```

5. Set some environment variables to create the kubeconfig file.

    ```sh
    export API_SERVER=172.30.10.20
    export CA_CRT=$(cat ca.crt | base64 -w 0)
    export USER_CRT=$(cat ${USERNAME}.crt | base64 -w 0)
    export USER_KEY=$(cat ${USERNAME}.key | base64 -w 0)
    ```

6. Create a kubeconfig file for user `jane`.

    ```sh
    cat <<EOF | tee $USERNAME-config > /dev/null
    apiVersion: v1
    kind: Config
    current-context: ${USERNAME}@kubernetes
    clusters:
    - name: kubernetes
      cluster:
        certificate-authority-data: ${CA_CRT}
        server: https://${API_SERVER}:6443
    contexts:
    - name: ${USERNAME}@kubernetes
      context:
        cluster: kubernetes
        user: ${USERNAME}
    users:
    - name: ${USERNAME}
      user:
        client-certificate-data: ${USER_CRT}
        client-key-data: ${USER_KEY}
    EOF
    ```

5. Set the `KUBECONFIG` environment variable to the just created kubeconfig file.

    ```sh
    export KUBECONFIG=$USERNAME-config
    ```

6. View the generated kubeconfig file.

    ```sh
    kubectl config view
    ```

7. Verify `jane` can create Role resources in the `default` namespace:

    ```sh
    kubectl auth can-i create roles
    ```

    The output is similar to this:

    ```plaintext
    yes
    ```

    But `jane` can not create Role resources in the `kube-system` namespace:

    ```sh
    kubectl auth can-i create roles --namespace kube-system
    ```
  
    The output is similar to this:

    ```plaintext
    no
    ```

    This is because you created a RoleBinding between the `admin` ClusterRole and the `admin` group **only** in the `default` namespace.

8. Unset the `KUBECONFIG` environment variable.

    ```sh
    unset KUBECONFIG
    ```

## Next

[Lab 05](./lab05.md)