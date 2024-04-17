# Lab 06

In this lab you are going to use Services to expose Pods to the cluster. Then you are going to install an Ingress Controller to forward traffic to the right service based on the HTTP URI.

## Creating a Service

So you have pods running the `hello-app` in a flat, cluster wide, address space. In theory, you could talk to these pods directly, but:

* What happens when a Pod gets recreated or the Deployment gets updated to a new version? The Deployment will create new ones, with different IPs. 

* How to load-balance requests among multiple replicas?

These are problems a Service solves.

🖥️ Open a shell in the `student` machine.

1. Create a service for your `hello-app` replicas by exposing the deployment which forwards every request arriving on port `80` to port `8080` of the endpoints.

    ```sh
    kubectl expose deployment hello-app --port 80 --target-port 8080
    ```

    This is equivalent to `kubectl apply -f` the following yaml:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: hello-app
    spec:
      selector:
        app: hello-app
      ports:
      - name: http
        port: 80
        targetPort: 8080
    ```

    This will create a Service which targets TCP port `8080` on any Pod with the `app: hello-app` label, and expose it on an the Service TCP port `80`.
    Being a Service of type `ClusterIP` (default if `type` is not specified), it is only usable inside the cluster.

2. Check the Service:

    ```sh
    kubectl get services
    ```

    Service is backed by a group of Pods that are exposed through EndpointSlices. The Service's selector will be evaluated continuously and the results will be POSTed to an EndpointSlice that is connected to the Service using a labels. When a Pod dies, it is automatically removed from the EndpointSlices that contains it as an endpoint. New Pods that match the Service's selector will automatically get added to an EndpointSlice for that Service. 
  
3. Check the endpoints, and note that the IPs are the same as the Pods created at the end of Lab 04.

    ```sh
    kubectl describe service hello-app
    ```

<!-- ## Service Routing

How are Services implemented? The default Kubernetes implementation is to let the kube-proxy (which usually runs under a DaemonSet on every node in the cluster) modify the iptables with DNAT rules.

1. Let's look for your service in the NAT table.

    ```sh
    sudo iptables -n -t nat -L KUBE-SERVICES | grep $CLUSTER_IP
    ```

    The output is similar to this:

    ```plaintext
    target     prot opt source               destination
    KUBE-SVC-KQHEELORMTTLHDA7  tcp  --  0.0.0.0/0            10.96.201.171        /* default/hello-app cluster IP */ tcp dpt:80
    ```

    The above rule states that everytime a tcp connection heading to `10.96.201.171` on port `80` is processed, jump to target chain `KUBE-SVC-KQHEELORMTTLHDA7` -->



## Accessing the Service from other Pods

Kubernetes offers a DNS cluster addon Service that automatically assigns dns names to other Services. It came up when you istalled the CNI plugin.

🖥️ Open a shell in the `student` machine.

1. Let's run another curl application to test this:

    ```sh
    kubectl run curl --image=fbarbarulo/nettools -i --tty --rm
    ```

2. Let's resolve the `hello-app` Service name.

    ```sh
    nslookup hello-app
    ```

    **Note**: The resolved IP address is the same as the one printed by `kubectl get services`.

3. Test the random load balancer mechanism implemented by the Service. Run the command below multiple times and verify you get replies from different Pods.

    ```sh
    curl hello-app
    ```

4. Run `exit` to close the session.

## Expose the application publicly

Often front-end applications need to be reached from the outside world. The very basic solution is to use a `NodePort` service.

🖥️ Open a shell in the `student` machine.

1. Delete the ClusterIP service you previously created.

    ```sh
    kubectl delete service hello-app
    ```

2. Create a new `NodePort` service from a YAML manifest selecting the target Pods using the label `app=hello-app`.

    ```sh
    echo '
    apiVersion: v1
    kind: Service
    metadata:
      name: hello-app
    spec:
      type: NodePort
      selector:
        app: hello-app
      ports:
      - name: http
        port: 80
        targetPort: 8080
    ' | kubectl apply -f -
    ```

4. List the services:

    ```sh
    kubectl get services
    ```

    You should see an output like the following:

    ```plaintext
    NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    kubernetes            ClusterIP   10.96.0.1      <none>        443/TCP        5h
    hello-app             NodePort    10.96.138.36   <none>        80:31203/TCP   13s
    ```

    The `hello-app` service is now of type `NodePort` and the assigned port is `31203`.
    
    **Note**: The port number may differ from yours. 

5. Take note of the exposed port and the worker node IP address.

    ```sh
    NODE_PORT=$(kubectl get services/hello-app -o jsonpath={.spec.ports[0].nodePort})
    WORKER_NODE_IP=172.30.10.21
    ```

6. Use curl to make an HTTP request specifying the IP address and port of the worker node.

    ```sh
    curl http://$WORKER_NODE_IP:$NODE_PORT
    ```

    Hooray! The application is now reachable from the world.

7. Try to use the IP address of the control-plane node. What do you expect? 

    ```sh
    CP_NODE_IP=172.30.10.20
    curl http://$CP_NODE_IP:$NODE_PORT
    ```

    Yes, it works. When a Service of type `NodePort` is created, Kubernetes binds the Service port to **every** node of the cluster.

7. Clean up deleting both the `hello-app` Deployment and the Service.

    ```sh
    kubectl delete deployment hello-app
    kubectl delete service hello-app
    ```

## Install an Ingress Controller

The downside of externally exposed services, like `NodePort` or `LoadBalancer`, is that you need to keep track of a bunch of IPs and ports.

Kubernetes introduced an ingress framework to allow a single externally facing gateway to route HTTP/HTTPS traffic to multiple backend services. 

Traffic routing is controlled by sets of rules defined by Ingress resources that are fulfilled by an Ingress Controller.
Unlike other types of controllers which run as part of the kube-controller-manager binary, Ingress controllers are not started automatically with a cluster.

There are several open-source Ingress Controller implementations. You are going to deploy the [NGINX ingress controller](https://kubernetes.github.io/ingress-nginx/).

🖥️ Open a shell in the `student` machine.

1. Deploy the ingress controller.

    ```sh
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml
    ```

    As the output shows, the manifest applied above creates a new namespace called `ingress-nginx`, plus a bunch of resources needed by the controller to function properly, including the service named `ingress-nginx-controller` and the IngressClass `nginx` (`kubectl get ingressclasses`).

2. Verify the controller is up and running.

    ```sh
    kubectl get deployments -n ingress-nginx
    ```

    **Note**: Since the controller has not been deployed in the `default` namespace, we need to include the `-n <namespace>` flag to list resources in the specified namespace.

    The output is similar to this:

    ```plaintext
    NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
    ingress-nginx-controller   1/1     1            1           44s
    ```

3. Let's show the `ingress-nginx-controller` Service.

    ```sh
    kubectl get service ingress-nginx-controller -n ingress-nginx
    ```

    The output is similar to this:

    ```plaintext
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.96.186.119   <pending>     80:30958/TCP,443:31600/TCP   1m2s
    ```

    By default, this Service is of type `LoadBalancer` and the assignment of an external IP is in the `pending` status. Howerver a Service of type `LoadBalancer` includes all the functionalities of the `NodePort` one. In fact, the service is already exposed on port `30958` and `31600` of the host.

4. Update the Service `type` field to `NodePort`.

    ```sh
    kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "NodePort"}}'
    ```

## Ingress Fan Out

A fanout configuration routes traffic from a single IP address to more than one Service, based on the HTTP URI being requested.

Now you are going to create two Deployments of different versions of the same application with each respective Services. Both of them will be accessible through the Ingress Controller at path respectively `/v1` and `/v2`.

🖥️ Open a shell in the `student` machine.

1. Create the `v1` Deployment.

    ```sh
    kubectl create deployment hello-app-v1 --image=gcr.io/google-samples/hello-app:1.0
    ```

2. Expose the `v1` Deployment on port `8001`.

    ```sh
    kubectl expose deployment hello-app-v1 --port 8001 --target-port 8080
    ```

3. Create the `v2` Deployment.

    ```sh
    kubectl create deployment hello-app-v2 --image=gcr.io/google-samples/hello-app:2.0
    ```

4. Expose the `v2` Deployment on port `8002`.

    ```sh
    kubectl expose deployment hello-app-v2 --port 8002 --target-port 8080
    ```

5. Create the Ingress resource with a rule with two paths, one per application version.

    ```sh
    echo '
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: hello-app-ingress
    spec:
      ingressClassName: nginx
      rules:
      - http:
          paths:
          - path: /v1
            pathType: Prefix
            backend:
              service:
                name: hello-app-v1
                port:
                  number: 8001
          - path: /v2
            pathType: Prefix
            backend:
              service:
                name: hello-app-v2
                port:
                  number: 8002
    ' | kubectl apply -f -
    ```

    **Note**: In order to attach this Ingress to the right Ingress Controller you must specify the `ingressClassName: nginx`. 

6. Verify you can reach both versions of the `hello-app` using the Ingress Controller Service.

    ```sh
    IC_NODE_PORT=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath={.spec.ports[0].nodePort})
    curl http://$WORKER_NODE_IP:$IC_NODE_PORT/v1
    ```

    The output is similar to this:

    ```plaintext
    Hello, world!
    Version: 1.0.0
    Hostname: hello-app-v1-755c49459-c2g7z
    ```

    Try to use the `/v2` path.

    ```sh
    curl http://$WORKER_NODE_IP:$IC_NODE_PORT/v2
    ```

    The output is similar to this:

    ```plaintext
    Hello, world!
    Version: 2.0.0
    Hostname: hello-app-v2-7796f8f5-hf25b
    ```

## Clean up

🖥️ Open a shell in the `student` machine.

1. Delete Deployment and Service resources you created in the steps before.

    ```sh
    kubectl delete deployment hello-app-v1
    kubectl delete deployment hello-app-v2
    kubectl delete service hello-app-v1
    kubectl delete service hello-app-v2
    kubectl delete ingress hello-app-ingress
    ```

## Next

[Lab 07](./lab07.md)