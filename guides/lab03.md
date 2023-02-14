# Lab 03

In this lab you are going to install Kubernetes as all-in-one single-node deployment and access it.

Open the terminal and run the following commands listed below.

## Install Kubernetes

1. Install a single control-plane Kubernetes cluster.

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/k8s-no-cni-install.sh | sh
    ```

    The script prepares the host by installing and configuring prerequisites (e.g. enabling IPv4 forwarding and letting iptables see bridged traffic), a container runtime (`containerd` and `runc`), `kubeadm`, `kubelet` and `kubectl`.
    Then it lanches the `kubeadm init` command to bootstrap the control-plane Kubernetes node.

2. Once the installation is completed, you can connect to the API server and check the nodes status.

    ```sh
    kubectl get node
    ```

    You should see the following message:

    ```plaintext
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

    This is due to the lack of a kubeconfig file. The `kubectl` command-line tool uses kubeconfig files to find the information it needs to choose a cluster and communicate with the API server of a cluster.
    By default, `kubectl` looks for a file named config in the `$HOME/.kube` directory.

## Create the kubeconfig file

1. Before creating a kubeconfig file you need a client certificate signed by Kubernetes CA to let Kubernetes authenticate us. Generate admin keys:

    ```sh
    openssl genrsa -out admin.key 2048
    ```

2. Generate a _Certificate Signing Request_:

    ```sh
    openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
    ```

    **Note**: By default, Kubernetes comes up with a super-user ClusterRole called `cluster-admin` bound to `system:masters` group. 

3. Sign the certificate using the CA key and certificate of Kubernetes cluster instance stored in `/etc/kubernetes/pki` directory:
    ```sh
    sudo openssl x509 -req -in admin.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out admin.crt
    sudo chown $USER:$USER admin.crt
    ```

4. Generate the kubeconfig file tied with the admin key and certificate just created.

    ```sh
    export CA_CRT=$(cat /etc/kubernetes/pki/ca.crt | base64 -w 0)
    export KEY=$(cat admin.key | base64 -w 0)
    export CERT=$(cat admin.crt | base64 -w 0)
    export API_SERVER=$(hostname -I | awk '{print $1}')
    cat <<EOF | tee .kube/config > /dev/null
    apiVersion: v1
    kind: Config
    current-context: kubernetes-admin@kubernetes
    clusters:
    - name: kubernetes
      cluster:
        certificate-authority-data: $CA_CRT
        server: https://$API_SERVER:6443
    contexts:
    - name: kubernetes-admin@kubernetes
      context:
        cluster: kubernetes
        user: kubernetes-admin
        namespace: default
    users:
    - name: kubernetes-admin
      user:
        client-certificate-data: $CERT
        client-key-data: $KEY
    EOF
    ```

5. View the generated kubeconfig file.

    ```sh
    kubectl config view
    ```

6. Now you should be able to access the API server.

    ```sh
    kubectl get nodes
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

    In the next lab you are going to solve this issue.

## Next

[Lab 04](./lab04.md)