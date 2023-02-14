# Lab 04

In this lab you are going to install the Cilium CNI plugin and create, scale und update a Deployment.

Open the terminal and run the following commands listed below.

## Install a CNI plugin

1. Kubernetes is not opinionated, it lets you choose your own CNI solution. Until a CNI plugin is installed the cluster will be inoperable. List the running Pods in all namespaces (`-A`):

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

    Great! Now if you take a look at the cluster it should be in the `Ready` status.

    Let's take a look at the running Pods too by running `kubectl get pod -n kube-system`. CoreDNS and Cilium pods are now running.

    Note that the Pods you have so far are part of the Kubernetes system itself, therefor they run in a namespace called `kube-system`.

## Deploy an application

1. Let’s deploy our first app on Kubernetes with the kubectl create deployment command. You need to provide the deployment name and app image location.

    ```sh
    kubectl create deployment hello-app --image=gcr.io/google-samples/hello-app:1.0
    ```

    Great! You just deployed your first application by creating a deployment in the `default` namespace. This performed a few things for you:
    * searched for a suitable node where an instance of the application could be run (you have only 1 available node);
    * scheduled the application to run on that Node;
    * configured the cluster to reschedule the instance on a new Node when needed.

2. List the deployments by running:

    ```sh
    kubectl get deployments
    ```

    You should see `0/1` in the `READY` column. It represents the ratio of `CURRENT/DESIRED` replicas. This means that the pod seems not to come up. Let's invenstigate more.

3. List Pods and take note of the pod name.

    ```sh
    kubectl get pods
    export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{end}}')
    ```

4. Dig deeply in the Pod details.

    ```sh
    kubectl describe pod $POD_NAME
    ```

    You should see an error like the following:

    ```plaintext
    Type     Reason            Age    From               Message
    ----     ------            ----   ----               -------
    Warning  FailedScheduling  2m49s  default-scheduler  0/1 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
    ```

    This means that the scheduler did not find any available nodes since the only node in the cluster belongs to the control plane. By default, Kubernetes prevents scheduling to control plane nodes by tainting them with `node-role.kubernetes.io/control-plane:NoSchedule`.

5. Untaint the node to allow scheduling on the control plane node.

    ```sh
    kubectl taint node --all node-role.kubernetes.io/control-plane-
    ```

6. Now the deployment should be ready. If not, delete (`kubectl delete deployment hello-app`) and recreate it.

7. Run the following command to see the ReplicaSet created by the Deployment.

    ```sh
    kubectl get replicasets
    ```

    The output is similar to this:

    ```sh
    NAME                   DESIRED   CURRENT   READY   AGE
    hello-app-5c7f66c6b6   1         1         1       1m8s
    ```

    **Note**: The name of the ReplicaSet is always formatted as `[DEPLOYMENT-NAME]-[HASH]`. This name will become the basis for the Pods which are created.

8. The Deployment automatically generates labels for each Pod in order to use them in the selctor. Run the following to see the Pod's labels

    ```sh
    kubectl get pods --show-labels
    ```

## Explore the application

1. Anything that the application would normally send to STDOUT becomes logs for the container within the Pod. Retrieve these logs:

    ```sh
    kubectl logs $POD_NAME
    ```

    **Note**: You don't need to specify the container name, because you only have one container inside the pod.

2. You can execute commands directly on the container once the Pod is up and running. Let's list the environment variables:

    ```sh
    kubectl exec $POD_NAME -- env
    ```

3. Let's start a bash session in the Pod's container.

    ```sh
    kubectl exec -it $POD_NAME -- bash
    ```

4.  You can check that the application is up by running a curl command:

    ```sh
    curl localhost:8080
    ```

    **Note**: here you used localhost because you executed the command inside the NodeJS Pod.

5. To close the container session type:

    ```sh
    exit
    ```

## Scaling the deployment

In order to facilitate more load, you may need to scale up the number of replicas for a microservice.

1. Scale the deployment by running:

    ```sh
    kubectl scale deployments/hello-app --replicas=4
    ```

2. Show the deployments to verify the current number of replicas matches the desired one.

    ```sh
    kubectl get deployments
    ```

    You should see `4/4` in the `READY` column. If not, run again the command above.

3. The change was applied, and you have 4 instances of the application available. Next, let’s check if the number of Pods changed:

    ```sh
    kubectl get pods -o wide
    ```

4. There are 4 Pods now, with different IP addresses. The change was registered in the Deployment events log. To check that, use the describe command:

    ```sh
    kubectl describe deployments/hello-app
    ```

## Deploy a new version of the application

1. To update the image of the application to version 2 run:

    ```sh
    kubectl set image deployments/hello-app hello-app=gcr.io/google-samples/hello-app:2.0
    ```

    The command notified the Deployment to use a different image for your app and initiated a rolling update.

2. Check the status of the new Pods, and view the old one terminating.

    ```sh
    kubectl get pods -o wide
    ```

    **Note**: The new Pods get new IP addresses.

3. Verify the rollout is successfully completed

    ```sh
    kubectl rollout status deployment hello-app
    ```

4. Verify that the `hello-app` service has updated the endpoints with the new Pods IP addresses.

    ```sh
    kubectl describe service hello-app
    ```

5. You can check if the service is still accessible via the `NodePort` service by running:

    ```sh
    curl http://$HOST_IP:$NODE_PORT
    ```

    Now you should receive a reply like the following:

    ```plaintext
    Hello, world!
    Version: 2.0.0
    Hostname: hello-app-5c7f66c6b6-nqll9
    ```

6. Let's list the replicasets to see that the Deployment updated the Pods by creating a new ReplicaSet and scaling it up to 4 replicas, as well as scaling down the old ReplicaSet to 0 replicas.

    ```sh
    kubectl get replicasets
    ```

    The output is similar to this:

    ```plaintext
    NAME                   DESIRED   CURRENT   READY   AGE
    hello-app-5c7f66c6b6   4         4         4       15m
    hello-app-f4b774b69    0         0         0       18s
    ```

## Rolling back a deployment

1. Suppose that you made a typo while updating the Deployment, by putting the image name as `hello-app:2.1` instead of `hello-app:2.0`.

    ```sh
    kubectl set image deployments/hello-app hello-app=gcr.io/google-samples/hello-app:2.1
    ```

2. The rollout gets stuck. You can verify it by checking the rollout status:

    ```sh
    kubectl rollout status deployment hello-app
    ```

    The output is similar to this:

    ```plaintext
    Waiting for rollout to finish: 2 out of 4 new replicas have been updated...
    ```
    Press Ctrl-C to stop the above rollout status watch.

3. Looking at the Pods created, you see that 2 Pods created by new ReplicaSet is stuck in an image pull loop.

    ```sh
    kubectl get pods
    ```

    The output is similar to this:

    ```plaintext
    NAME                         READY   STATUS             RESTARTS   AGE
    hello-app-5c7f66c6b6-dm2zn   1/1     Running            0          35m
    hello-app-5c7f66c6b6-fklpb   1/1     Running            0          35m
    hello-app-5c7f66c6b6-nqll9   1/1     Running            0          35m
    hello-app-6f7cc84b47-2mqll   0/1     ImagePullBackOff   0          10s
    hello-app-6f7cc84b47-qhpwp   0/1     ImagePullBackOff   0          10s
    ```

    **Note**: The Deployment controller stops the bad rollout automatically, and stops scaling up the new ReplicaSet.

4. To fix this, you need to rollback to a previous revision of Deployment that is stable.

    ```sh
    kubectl rollout undo deployment hello-app
    ```

5. Check if the rollback was successful and the Deployment is running as expected, run:

    ```sh
    kubectl get deployment hello-app
    ```

    The output is similar to this:

    ```plaintext
    NAME        READY   UP-TO-DATE   AVAILABLE   AGE
    hello-app   4/4     4            4           1m21s
    ```

## Next

[Lab 05](./lab05.md)