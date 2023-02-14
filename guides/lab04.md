# Lab 04

In this lab you are going to install the Cilium CNI plugin and explore the Kubernetes core concepts.

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

    Great! Now if we take a look at the cluster it should be in the `Ready` status.

    Let's take a look at the running Pods too by running `kubectl get pod -n kube-system`. CoreDNS and Cilium pods are now running.

    Note that the Pods we have so far are part of the Kubernetes system itself, therefor they run in a namespace called `kube-system`.

## Deploy an application

1. Let’s deploy our first app on Kubernetes with the kubectl create deployment command. We need to provide the deployment name and app image location.

    ```sh
    kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
    ```

    Great! You just deployed your first application by creating a deployment in the `default` namespace. This performed a few things for you:
    * searched for a suitable node where an instance of the application could be run (we have only 1 available node);
    * scheduled the application to run on that Node;
    * configured the cluster to reschedule the instance on a new Node when needed.

2. List the deployments by running:

    ```sh
    kubectl get deployments
    ```

    You should see `0/1` in the `READY` column. It represents the ratio of `CURRENT/DESIRED` replicas. This means that the pod seems not to come up. Let's invenstigate more.

3. List Pods and take note of the `kubernetes-bootcamp` pod name.

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

6. Now the deployment should be ready. If not, delete (`kubectl delete deployment kubernetes-bootcamp`) and recreate it.

## Explore the application

1. Anything that the application would normally send to STDOUT becomes logs for the container within the Pod. Retrieve these logs:

    ```sh
    kubectl logs $POD_NAME
    ```

    **Note**: We don't need to specify the container name, because we only have one container inside the pod.

2. We can execute commands directly on the container once the Pod is up and running. Let's list the environment variables:

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

    **Note**: here we used localhost because we executed the command inside the NodeJS Pod.

5. To close the container connection type:

    ```sh
    exit
    ```

## Verify Pod-to-Pod communication

1. In a microservice architecture services in Pods need to communicate to each other. First we need to take note of its IP address.  

    ```sh
    export POD_IP=$(kubectl get pods -o go-template --template '{{range .items}}{{.status.podIP}}{{end}}')
    ```

2. Let's create a client Pod from which we can make HTTP requests to the `kubernetes-bootcamp` server. In this case we are going to create a YAML manifest describing the Pod object, which is the recommended way to create Kubernetes resources.

    ```sh
    cat <<EOF | tee client-pod.yaml > /dev/null
    apiVersion: v1
    kind: Pod
    metadata:
      name: client
    spec:
      containers:
      - name: shell
        image: busybox
        tty: true
        env:
        - name: KUBERNETES_BOOTCAMP
          value: "$POD_IP"
        resources:
          limits:
            cpu: "100m"
            memory: "128Mi"
    EOF
    kubectl apply -f client-pod.yaml
    ```

3. Let's start a shell session in it.

    ```sh
    kubectl exec -it client -- sh
    ```

4. Make an HTTP request and verify that you get a response.

    ```sh
    wget -qO - http://$KUBERNETES_BOOTCAMP:8080
    ```

5. Close the connection.

    ```sh
    exit
    ```

## Scaling the deployment

In order to facilitate more load, we may need to scale up the number of replicas for a microservice.

1. Scale the deployment by running:

    ```sh
    kubectl scale deployments/kubernetes-bootcamp --replicas=4
    ```

2. Show the deployments to verify the current number of replicas matches the desired one.

    ```sh
    kubectl get deployments
    ```

    You should see `4/4` in the `READY` column. If not, run again the command above.

3. The change was applied, and we have 4 instances of the application available. Next, let’s check if the number of Pods changed:

    ```sh
    kubectl get pods -o wide
    ```

4. There are 4 Pods now, with different IP addresses. The change was registered in the Deployment events log. To check that, use the describe command:

    ```sh
    kubectl describe deployments/kubernetes-bootcamp
    ```

## Load balancing

Now that we have multiple replicas of the application we need a way to load balance requests among them.

**Services** allow us to hide the ephimeral nature of Pods and to implement a random load balancing mechanism using a fixed front-end IP address and an associated domain name internally resolvable.

1. Expose the deployment using a service which forwards every request arriving on port `80` to port `8080` of the endpoints.

    ```sh
    kubectl expose deployment kubernetes-bootcamp --port 80 --target-port 8080
    ```

2. Listing all services you should see the one just created.

    ```sh
    kubectl get services
    ```

    **Note**: The service has received a unique ClusterIP and an entry in the cluster DNS has been created.

3. Open a shell session in the `client` pod.

    ```sh
    kubectl exec -it client -- sh
    ```

4. Verify you get the same response using the service name as hostname in the request.

    ```sh
    wget -qO - http://kubernetes-bootcamp
    ```

    > 💡 Run the above command multiple times to see how requests are load balanced among the four replicas.

5. Close the session to the client Pod.

    ```sh
    exit
    ```

## Expose the application publicly

Often front-end microservices need to be reached from the outside world. The very basic solution is to use a `NodePort` service.

1. Let's update the `kubernetes-bootcamp` service making it of type `NodePort`.

    ```sh
    kubectl patch service kubernetes-bootcamp -p '{"spec": {"type": "NodePort"}}'
    ```

2. List the services:

    ```sh
    kubectl get services
    ```

    You should see an output like the following:

    ```plaintext
    NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    kubernetes            ClusterIP   10.96.0.1      <none>        443/TCP        3d5h
    kubernetes-bootcamp   NodePort    10.96.138.36   <none>        80:31203/TCP   2d23h
    ```

    The `kubernetes-bootcamp` service is now of type `NodePort` and the assigned port is `31203`.
    
    **Note**: The port number may differ from yours. 

3. Let's take note of it:

    ```sh
    export NODE_PORT=$(kubectl get services/kubernetes-bootcamp -o go-template='{{(index .spec.ports 0).nodePort}}')
    ```

4. Use curl to make an HTTP request, this time from outside the cluster using the IP address and port of the host.

    ```sh
    export HOST_IP=$(hostname -I)
    curl http://$IP:$NODE_PORT
    ```

    Hooray! The application is now reachable from the world.