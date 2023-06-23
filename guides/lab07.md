# Lab 07

In this lab you are going to perisist data in Kubernetes using PersistenVolumes (PVs), PersistentVolumeClaims (PVCs) and StorageClasses (SCs).

## Install the hostpath CSI driver

As you did with the CNI plugin, you need to let Kubernetes be able to interact with a storage via a CSI driver. In this lab you are going to use the hostpath CSI driver which provides persistent storage backed by the host filesystem.

Open a shell on the `student` machine.

1. Install the CSI driver with the required RBAC rules in the `csi` namespace:

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/csi-hostpath-install.sh | sh
    ```

2. The manifest applied above has deployed the CSI driver as StatefulSet. Verify it is up and running.

    ```sh
    kubectl get statefulsets
    ```

    Show also the pods.

    ```sh
    kubectl get pods
    ```

    The output is similar to this:

    ```plaintext
    NAME                   READY   STATUS    RESTARTS   AGE
    csi-hostpathplugin-0   8/8     Running   0          54s
    ```

3. Inspect the Pod to see the containers inside it.

    ```sh
    kubectl describe pod csi-hostpathplugin-0
    ```

    The first container you see is the `hostpath` one which implements all functions to communicate to the backed storage.

    It comes with a bunch of CSI sidecar containers that aim to simplify the development and deployment of CSI Drivers on Kubernetes: 

    * `csi-external-health-monitor-controller` checks the health condition of the CSI volumes.
    * `node-driver-registrar` registers the CSI driver with Kubelet so that it knows which Unix domain socket to issue the CSI calls on.
    * `liveness-probe` exposes an HTTP `/healthz` endpoint, which serves as kubelet's livenessProbe hook to monitor health of a CSI driver.
    * `csi-attacher` attaches volumes to nodes by calling `ControllerPublish` and `ControllerUnpublish` functions of CSI drivers.
    * `csi-provisioner` dynamically provisions volumes by calling `CreateVolume` and `DeleteVolume` functions of CSI drivers.
    * `csi-resizer` watches the Kubernetes API server for PersistentVolumeClaim updates and triggers `ControllerExpandVolume` operations against a CSI endpoint if user requested more storage on PersistentVolumeClaim object.
    * `csi-snapshotter` watches for `VolumeSnapshotContent` create/update/delete events to perform snapshots of PersistenVolumes.

4. Kubernetes API make available a `CSIDriver` resource to (i) ease the discovery of CSI Drivers installed on the cluster; (ii) specify how Kubernetes should interact with the CSI driver. List the CSI drivers.

    ```sh
    kubectl get CSIDriver
    ```

    The output is similar to this:

    ```plaintext
    NAME                  ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
    hostpath.csi.k8s.io   true             true             false             <unset>         false               Persistent,Ephemeral   45m
    ```

## Enable dynamic volume provisionig

A cluster administrator can define as many `StorageClass` objects as needed, each specifying a _volume plugin_ (aka `provisioner`) that provisions a volume and the set of parameters to pass to that provisioner when provisioning. A cluster administrator can define and expose multiple flavors of storage (from the same or different storage systems) within a cluster, each with a custom set of parameters. This design also ensures that end users don't have to worry about the complexity and nuances of how storage is provisioned, but still have the ability to select from multiple storage options.

1. Create a StorageClass which refers to the `hostpath.csi.k8s.io` provisioner:

    ```sh
    echo '
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: csi-hostpath-sc
    provisioner: hostpath.csi.k8s.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    allowVolumeExpansion: true
    ' | kubectl apply -f -
    ```

2. Verify the StorageClass has been created

    ```sh
    kubectl get storageclasses
    ```

    The output is similar to this:

    ```plaintext
    NAME              PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
    csi-hostpath-sc   hostpath.csi.k8s.io   Delete          Immediate           true                   9s
    ```

3. An administrator can mark a specific `StorageClass` as default by adding the `storageclass.kubernetes.io/is-default-class` annotation to it. When a default `StorageClass` exists in a cluster and a user creates a `PersistentVolumeClaim` with `storageClassName` unspecified, the `DefaultStorageClass` admission controller automatically adds the `storageClassName` field pointing to the default storage class.
Mark the `csi-hostpath-sc` StorageClass as _default_.

    ```sh
    kubectl annotate storageclass csi-hostpath-sc storageclass.kubernetes.io/is-default-class=true 
    ```

4. Now if you show the `csi-hostpath-sc` Storage Class you should see the `(default)` annotation.

    ```sh
    kubectl get storageclass csi-hostpath-sc
    ```

## Using dynamic provisioning

Users request dynamically provisioned storage by including a storage class in their `PersistentVolumeClaim`.

1. Create a claim that uses the `csi-hostpath-sc` StorageClass.

    ```sh
    echo '
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: csi-pvc
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: csi-hostpath-sc # can be omitted (default class)
    ' | kubectl apply -f -
    ```

2. Verify the PV has been automatically created and successfully bound to the PVC.

    ```sh
    kubectl get persistentvolumes
    ```

    The output is similar to this:

    ```sh
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
    pvc-40a54e68-3321-4686-864a-90fbeb0f6067   1Gi        RWO            Delete           Bound    default/csi-pvc   csi-hostpath-sc            4s
    ```

    To list the PVC run the following command.

    ```sh
    kubectl get persistentvolumeclaims
    ```

## Claims as volumes

1. Create a Deployment with a Pod using the claim as a volume.

    ```sh
    cat <<EOF | tee csi-app.yaml > /dev/null
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: csi-app
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: csi-app
      template:
        metadata:
          labels:
            app: csi-app
        spec:
          containers:
          - name: csi-app
            image: radial/busyboxplus:curl
            command: ["/bin/sh", "-c"]
            args: ["i=1; while true; do echo \"[\$HOSTNAME] counter: \$i\" >> /csi-data/logs.txt; i=\$((i+1)); sleep 5; done"]
            volumeMounts:
            - name: my-csi-volume
              mountPath: "/csi-data"
          volumes:
          - name: my-csi-volume
            persistentVolumeClaim:
              claimName: csi-pvc
    EOF
    kubectl apply -f csi-app.yaml
    ```

2. Verify the Deployment is up and running.

    ```sh
    kubectl get deployments
    ```

    The output is simlar to this:

    ```plaintext
    NAME      READY   UP-TO-DATE   AVAILABLE   AGE
    csi-app   1/1     1            1           22s
    ```

3. Check it is writing to the log file.

    ```sh
    POD_NAME=$(kubectl get pods -l app=csi-app -o jsonpath='{range .items[*]}{.metadata.name}{end}')
    kubectl exec -it $POD_NAME -- cat /csi-data/logs.txt
    ```

    The output is similar to this:

    ```plaintext
    [csi-app-9cf586df5-7h8vg] counter: 1
    [csi-app-9cf586df5-7h8vg] counter: 2
    [csi-app-9cf586df5-7h8vg] counter: 3
    [csi-app-9cf586df5-7h8vg] counter: 4
    [csi-app-9cf586df5-7h8vg] counter: 5
    [csi-app-9cf586df5-7h8vg] counter: 6
    ```

4. Delete and recreate the Deployment.

    ```sh
    kubectl delete deployment csi-app
    kubectl wait --for=delete pod/$POD_NAME --timeout=60s
    kubectl apply -f csi-app.yaml
    ```

5. Verify the log file still contains the old logs.

    ```sh
    POD_NAME=$(kubectl get pods -l app=csi-app -o jsonpath='{range .items[*]}{.metadata.name}{end}')
    kubectl exec -it $POD_NAME -- cat /csi-data/logs.txt
    ```

    The output is similar to this:

    ```plaintext
    [csi-app-9cf586df5-7h8vg] counter: 1
    [csi-app-9cf586df5-7h8vg] counter: 2
    [csi-app-9cf586df5-7h8vg] counter: 3
    [csi-app-9cf586df5-7h8vg] counter: 4
    [csi-app-9cf586df5-7h8vg] counter: 5
    [csi-app-9cf586df5-7h8vg] counter: 6
    [csi-app-9cf586df5-wr4pq] counter: 1
    [csi-app-9cf586df5-wr4pq] counter: 2
    [csi-app-9cf586df5-wr4pq] counter: 3
    ```

## Expanding a Persistent Volume Claim

A PVC can be expanded if and only if:

* the CSI driver supports this feature;
* the PVC is dinamically provisioned by a Storage Class that has `allowVolumeExpansion` parameter set to `true`.

**Note**: Persistent Volume Claims can not be shrinked.

The installed CSI driver and the created `StorageClass` enable you to expand PVCs.

1. Try to increase the size of the `csi-pvc` Persistent Volume Claim to `2Gi`.

    ```sh
    kubectl patch persistentvolumeclaim csi-pvc -p '{"spec": {"resources": {"requests": {"storage": "2Gi"}}}}'
    ```

2. Wait for a few seconds and then run `kubectl get pvc`. The `CAPACITY` should be increased to `2Gi`.

## Clean up

1. Delete Deployment and PVC resources.

    ```sh
    kubectl delete deployment csi-app
    kubectl wait --for=delete pod/$POD_NAME --timeout=60s
    kubectl delete persistentvolumeclaim csi-pvc
    ```

2. Verify the Persistent Volume is automatically deleted due to the `csi-hostpath-sc` Storage Class reclaim policy set to `Delete`.

    ```sh
    kubectl get persistentvolumes
    ```

    The output should be `No resources found`.

## Next

[Lab 08](./lab08.md)