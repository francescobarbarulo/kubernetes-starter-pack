# Final challenge

At this point, you are ready for challenging yourself with a non-guided lab. It is expected you try and fail, but it is just the learning process.

> The greatest mistake you can make in life is continually fearing that you'll make one. [Elbert Hubbard]

You are going to add a second worker node to your cluster. Then you will deploy the `getting-started` application you deployed with docker, but this time on your Kubernetes cluster.

The [Kubernetes official documentation](https://kubernetes.io/docs/home/) will be your travel buddy.

1. Join the `k8s-w-02` worker node to the existing cluster.

2. Create a new namespace named `europe` in the cluster.

3. Give admin access to a new user called `bob` in the `europe` namespace.

4. Use `bob` kubeconfig file to create the next Kubernetes resources in the `europe` namespace.

    **Tip**: Edit the kubectl context by setting the namespace instead of using the `-n europe` flag everytime you need to create a resource in the `europe` namespace:

    ```sh
    kubectl config set-context --current --namespace europe
    ```

5. Create a Deployment named `getting-started` based on the `getting-started:v2` image built in [lab02](./lab02.md) and pushed to the `registry` in [lab03](./lab03.md).

    * **Tip 1**: Verify the registry is up and running

    * **Tip 2**: In order to pull an image from a private container image registry you need to provide the credentials by means of a Secret.

        ```sh
        kubectl create secret docker-registry regcred \
        --docker-server=$REGISTRY \
        --docker-username=testuser \
        --docker-password=testpassword
        ```

        Rember to [use the Secret in the Pod template of the Deployment configuration](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-pod-that-uses-your-secret).

6. Expose the previous Deployment with a Service of type `ClusterIP` (the default).

7. Expose the Service via the existing Nginx ingress controller.

8. Test you can reach the application from the browser.