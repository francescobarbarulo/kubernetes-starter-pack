# Lab 07

In this lab you are going to deploy a Wordpress application with a MySQL database. Both applications use PersistentVolumes and PersistentVolumeClaims to store data.

## Deploy the MySQL database

1. Create a secret to store credentials to access the mysql.

    ```sh
    kubectl create secret generic mysql-creds --from-literal=user=wordpress --from-literal=password=secret123 --from-literal=db=wordpress
    ```

2. Create a Service resource for the database instance. Since the database is a stateful application it recommended to use a headless service.

    ```sh
    echo '
    apiVersion: v1
    kind: Service
    metadata:
      name: mysql
      labels:
        app: wordpress
    spec:
      clusterIP: None # headless
      selector:
        app: wordpress
        tier: mysql
      ports:
      - name: mysql
        port: 3306
    ' | kubectl apply -f -
    ```

3. Create the `mysql` StatefulSet setting the required `MYSQL_ROOT_PASSWORD` environment variable using the secret created ast step 1.

    ```sh
    echo '
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: mysql
      labels:
        app: wordpress
    spec:
      serviceName: mysql # must match the mysql Service name
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
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: db
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: user
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: password
            - name: MYSQL_RANDOM_ROOT_PASSWORD
              value: '1'
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
    ' | kubectl apply -f -
    ```

## Deploy Wordpress application

1. Create a PVC for Wordpress configuration data.

    ```sh
    echo '
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: wordpress-data
      labels:
        app: wordpress
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ' | kubectl apply -f -
    ```

    Verify the PVC has successfully created by `kubectl get pvc`.

2. Create a Deployment for Wordpress application with a Persistent Volume Claim reference to `wordpress-data`.

    ```sh
    echo '
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: wordpress
      labels:
        app: wordpress
    spec:
      selector:
        matchLabels:
          app: wordpress
          tier: frontend
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: wordpress
            tier: frontend
        spec:
          containers:
          - image: wordpress:6.1
            name: wordpress
            env:
            - name: WORDPRESS_DB_HOST
              value: mysql-0.mysql
            - name: WORDPRESS_DB_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: user
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: password
            - name: WORDPRESS_DB_NAME
              valueFrom:
                secretKeyRef:
                  name: mysql-creds
                  key: db
            ports:
            - containerPort: 80
            volumeMounts:
            - name: data
              mountPath: /var/www/html
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: wordpress-data
    ' | kubectl apply -f -
    ```

    The wordpress container requires the `WORDPRESS_DB_HOST` and `WORDPRESS_DB_PASSWORD` environment variables. The first is populated using the headless service in the expected format (`<pod-name>.<service-name>`); the second is populated from the `mysql-creds` secret.

    Verify the only replica of the Deployment is up and running by `kubectl get pods -l app=wordpress,tier=frontend`.


3. Create a `ClusterIP` Service for the wordpress Deployment.

    ```sh
    echo '
    apiVersion: v1
    kind: Service
    metadata:
      name: wordpress
      labels:
        app: wordpress
    spec:
      selector:
        app: wordpress
        tier: frontend
      ports:
      - name: http
        port: 80
    ' | kubectl apply -f -
    ```

4. Create an Ingress resource to expose to wordpress service outside the cluster.

    ```sh
    echo '
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: wordpress-ingress
      labels:
        app: wordpress
    spec:
      ingressClassName: nginx
      rules:
      - http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: wordpress
                port:
                  number: 80
    ' | kubectl apply -f -
    ```

    The wordpress is exposed through the Ingress Controller on the port of the ingress service. Get it by `kubectl get service -n ingress-nginx` and open the browser at `http://localhost:<nodePort>`.