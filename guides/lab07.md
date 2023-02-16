# Lab 07

In this lab you are going to deploy a Wordpress application with a MySQL database. Both applications use PersistentVolumes and PersistentVolumeClaims to store data.

## Deploy the MySQL database

1. Create a secret for the database credentials.

    ```sh
    kubectl create secret generic mysql-creds --from-literal=password=secret
    ```
2. Create a Headless Service.

    ```sh
    cat <<EOF | tee mysql-headless-svc.yaml > /dev/null
    apiVersion: v1
    kind: Service
    metadata:
      name: mysql
      labels:
        app: wordpress
    spec:
      clusterIP: None
      selector:
        app: wordpress
        tier: mysql
      ports:
      - port: 3306
    EOF
    kubectl apply -f mysql-headless-svc.yaml
    ```

3. Create a MySQL statefulset.

    ```sh
    cat <<EOF | tee mysql-statefulset.yaml > /dev/null
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: mysql
      labels:
        app: wordpress
    spec:
      serviceName: mysql
      replicas: 1
      selector:
        matchLabels:
          app: wordpress
          tier: mysql
      template:
        metadata:
          labels:
            app: wordpress
            tier: mysql
        spec:
          containers:
          - name: mysql
            image: mysql:5.7
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: password
            ports:
            - name: mysql
              containerPort: 3306
            volumeMounts:
            - name: data
              mountPath: /var/lib/mysql
      volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 5Gi
    EOF
    kubectl apply -f mysql-statefulset.yaml
    ```
