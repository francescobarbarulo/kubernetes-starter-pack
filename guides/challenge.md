# Final challenge

At this point, you are ready for challenging yourself with a non-guided lab.
You are going to add a second worker node to your cluster. Then you will deploy the `getting-started` application you deployed with docker, but this time on your Kubernetes cluster.

1. Join the `k8s-w-02` worker node to the existing cluster.

2. Create a new namespace named `europe` in the cluster.

3. Give admin access to a new user called `bob` in the `europe` namespace.

4. Use `bob` kubeconfig file to create the next Kubernetes resources in the `europe` namespace.

    **Tip**: Instead of using the `-n europe` flag everytime you need to create a resource in the `europe` namespace, edit the kubectl context by setting the namespace:

    ```sh
    kubectl config set-context --current --namespace europe
    ```

5. Create a Deployment based on the `getting-started:v2` image built in lab02 and pushed to the `registry` in lab03.

6. Expose the previous Deployment with a Service of type `ClusterIP` (the default).

7. Expose the Service via the existing Nginx ingress controller.

8. Test you can reach the application from the browser.