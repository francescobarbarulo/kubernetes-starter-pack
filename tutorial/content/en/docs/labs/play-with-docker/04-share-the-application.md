---
title: "4. Share the application"
description: "Now that we’ve built an image, let’s share it! To share Docker images, you have to use a Docker registry, in our case a local registry."
lead: "Now that we’ve built an image, let’s share it! To share Docker images, you have to use a Docker registry, in our case a local registry."
menu:
  docs:
    parent: "play-with-docker"
weight: 240
---

## Deploy the registry server

Docker provides a containerized local registry that can be started using the `docker run` command. You will also configure the registry server by providing native basic authentication.

1. Create a password file with one entry for the user `testuser`, with password `testpassword`:
    ```sh
    mkdir auth
    docker run \
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

3. After a few seconds, open your web browser at [`http://localhost:5000/v2/_catalog`](http://localhost:5000/v2/_catalog). You should see an empty json response `{}`.

## Push the image

1. In the command line, try running the push command:
    ```sh
    docker push getting-started
    ```

    You probably saw an error like this:

    ```plaintext
    The push refers to repository [docker.io/library/getting-started]
    denied: requested access to the resource is denied
    ```

    The error occurred because the `docker push` command uses the Docker's public registry if it is not specified in the image name.

2. Use the `docker tag` command to give the `getting-started` image a new name, including the registry hostname. If you don't specify a tag, Docker will use a tag called `latest`.

    ```sh
    docker tag getting-started localhost:5000/getting-started
    ```

3. Before pushing the renamed image, login to the local registry using `testpassword` as password when prompted.

    ```sh
    docker login localhost:5000 -u testuser
    ```

4. Now try to push again.

    ```sh
    docker push localhost:5000/getting-started
    ```

## Run the image pulled from the local registry

Now that you pushed the image on the registry, you can safely remove the image from your machine. This to also reproduce a new instance on which you deploy your containerized application.

1. Get the ID of the container by using the `docker ps` command.

    ```sh
    docker ps
    ```

2. Use the `docker rm` command to stop and remove the container. Replace <the-container-id> with the ID from `docker ps`.

    ```sh
    docker rm -f <the-container-id>
    ```

3. Use the `docker rmi`command to remove the image:

    ```sh
    docker rmi localhost:5000/getting-started
    docker rmi getting-started
    ```

4. Now that the `getting-started` image is not present on your machine, you need to pull it from the local registry. This is done automatically with the `docker run` command:

    ```sh
    docker run -d -p 8080:3000 localhost:5000/getting-started
    ```

    You should see the image get pulled down and eventually start up!

5. Reopen your web browser to [`http://localhost:8080`](http://localhost:8080). You should see the app with your modifications.


