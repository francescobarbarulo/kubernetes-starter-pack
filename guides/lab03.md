# Lab 03

In this lab you are going to deploy a private registry used to store your container images and push the `getting-started` image to it.

## Deploy the registry server

Docker provides a containerized local registry that can be started using the `docker run` command. You will also configure the registry server by providing native basic authentication.

Open a shell in the `registry` environment.

1. Install Docker Engine:

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/docker-install.sh | sh
    ```

2. Create a password file tool with one entry for the user `testuser`, with password `testpassword`, using the `htpasswd` tool provided in the `httpd` image:
    ```sh
    mkdir auth && docker run \
    --entrypoint htpasswd \
    httpd:2 -Bbn testuser testpassword > auth/htpasswd
    ```

3. Start the registry with basic authentication:
    ```sh
    docker run -d \
    -p 5000:5000 \
    --name registry \
    -v $PWD/auth:/auth \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
    registry:2
    ```

4. After a few seconds, open the web browser at [`http://172.30.10.11:5000/v2/_catalog`](http://172.30.10.11:5000/v2/_catalog). Use the above credentials when requested. You should see an empty json response:

    ```json
    {"repositories":[]}
    ```

## Push the image to the registry

Once you built the app container image, you are ready to push it to your container registry.

Open a shell in the `dev` environment.

1. Try running the push command:
    ```sh
    docker push getting-started:v2
    ```

    You probably saw an error like this:

    ```plaintext
    The push refers to repository [docker.io/library/getting-started]
    denied: requested access to the resource is denied
    ```

    The error occurred because the `docker push` command uses the Docker's public registry if it is not specified in the image name.

2. Take note of the `registry` IP address.

    ```sh
    export REGISTRY=172.30.10.11
    ```

3. Configure Docker to contact the `registry` using HTTP.

    ```sh
    cat <<EOF | tee /etc/docker/daemon.json > /dev/null
    {
        "insecure-registries" : ["http://$REGISTRY:5000"]
    }
    EOF
    ```

4. Restart Docker daemon.

    ```sh
    systemctl restart docker
    ```

5. Use the `docker tag` command to give the `getting-started` image a new name, including the registry hostname. If you don't specify a tag, Docker will use a tag called `latest`.

    ```sh
    docker tag getting-started:v2 $REGISTRY:5000/getting-started:v2
    ```

6. Before pushing the renamed image, login to the local registry using `testpassword` as password when prompted.

    ```sh
    docker login $REGISTRY:5000 -u testuser
    ```

7. Now try to push again.

    ```sh
    docker push $REGISTRY:5000/getting-started:v2
    ```

8. Check the image is present on the registry by refreshing the web browser at [`http://172.30.10.11:5000/v2/_catalog`](http://172.30.10.11:5000/v2/_catalog). You should see a json response like this:

    ```json
    {"repositories":["getting-started"]}
    ```


## Next

[Lab 04](./lab04.md)