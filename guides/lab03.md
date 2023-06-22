# Lab 03

In this lab you are going to deploy a private container registry used to store your container images.

Open a shell in the `registry` environment.
You should see something similar to this:

```plaintext
root@registry:~#
```

## Deploy the registry server

Docker provides a containerized local registry that can be started using the `docker run` command. You will also configure the registry server by providing native basic authentication.

1. Create a password file tool with one entry for the user `testuser`, with password `testpassword`, using the `htpasswd` tool provided in the `httpd` image:
    ```sh
    cd && mkdir auth && docker run \
    --entrypoint htpasswd \
    httpd:2 -Bbn testuser testpassword > auth/htpasswd
    ```

2. Start the registry with basic authentication:
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

3. After a few seconds, open your web browser at `http://<registry>:5000/v2/_catalog`. Use the above credentials when requested. You should see an empty json response `{"repositories":[]}`.

4. Exit the `registry` environment.

## Push the image to the registry

Once you built the app container image, you are ready to push it to your container registry.

Open a shell in the `dev` environment.
You should see something similar to this:

```plaintext
root@dev:~#
```

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

2. Use the `docker tag` command to give the `getting-started` image a new name, including the registry hostname. If you don't specify a tag, Docker will use a tag called `latest`.

    ```sh
    docker tag getting-started:v2 <dev>:5000/getting-started:v2
    ```

3. Before pushing the renamed image, login to the local registry using `testpassword` as password when prompted.

    ```sh
    docker login <dev>:5000 -u testuser
    ```

4. Now try to push again.

    ```sh
    docker push <dev>:5000/getting-started:v2
    ```

5. Check the image is present on the registry by refreshing the web browser at `http://<dev>:5000/v2/_catalog`. You should see a json response like this:

    ```json
    {"repositories":["getting-started"]}
    ```


## Next

[Lab 04](./lab04.md)