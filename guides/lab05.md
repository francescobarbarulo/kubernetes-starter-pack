# Lab 05

In this lab you are going to use Services to expose Pods to the cluster.

Open the terminal and run the following commands listed below.

## Creating a Service

So you have pods running the `hello-app` in a flat, cluster wide, address space. In theory, you could talk to these pods directly, but:

* What happens when a Pod gets recreated or the Deployment gets updated to a new version? The Deployment will create new ones, with different IPs. 

* How to load-balance requests among multiple replicas?

These are problems a Service solves.

1. Create a service for your `hello-app` replicas by exposing the deployment. which forwards every request arriving on port `80` to port `8080` of the endpoints.

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

2. Check the Service:

    ```sh
    kubectl get services
    ```

    Service is backed by a group of Pods that are exposed through EndpointSlices. The Service's selector will be evaluated continuously and the results will be POSTed to an EndpointSlice that is connected to the Service using a labels. When a Pod dies, it is automatically removed from the EndpointSlices that contain it as an endpoint. New Pods that match the Service's selector will automatically get added to an EndpointSlice for that Service. 
  
3. Check the endpoints, and note that the IPs are the same as the Pods created at the end of Lab 04.

    ```sh
    kubectl describe service hello-app
    ```

4. You should now be able to curl the nginx Service on `<CLUSTER-IP>:<PORT>` from any node in your cluster.

    ```sh
    export CLUSTER_IP=$(kubectl get services hello-app -o go-template='{{(index .spec.clusterIP)}}')
    curl http://$CLUSTER_IP:80
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

1. Let's run another curl application to test this:

    ```sh
    kubectl run curl --image=radial/busyboxplus:curl -i --tty --rm
    ```

2. Let's resolve the `hello-app` Service name.

    ```sh
    nslookup hello-app
    ```

3. Test the random load balancer mechanism implemented by the Service. Run multiple times the command below and verify you get replies from different Pods.

    ```sh
    curl hello-app
    ```

4. Run `exit` to close the session.

## Expose the application publicly

Often front-end applications need to be reached from the outside world. The very basic solution is to use a `NodePort` service.

1. Delete the ClusterIP service you previously created.

    ```sh
    kubectl delete service hello-app
    ```

2. Create a new `NodePort` service from a YAML manifest selecting the target Pods using the label `app=hello-app`.

    ```sh
    cat <<EOF | tee service.yaml > /dev/null
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
    EOF
    kubectl apply -f service.yaml
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

5. Take note of the exposed port and verify the endpoints include the IP addresses of the Pods listed at step 2.

    ```sh
    export NODE_PORT=$(kubectl get services/hello-app -o go-template='{{(index .spec.ports 0).nodePort}}')
    kubectl describe service hello-app
    ```

6. Use curl to make an HTTP request, this time from outside the cluster using the IP address and port of the host.

    ```sh
    export HOST_IP=$(hostname -I | awk '{print $1}')
    curl http://$HOST_IP:$NODE_PORT
    ```

    Hooray! The application is now reachable from the world.

## Ingress [TODO]