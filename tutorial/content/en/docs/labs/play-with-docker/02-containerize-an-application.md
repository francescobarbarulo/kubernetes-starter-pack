---
title: "2. Containerize an application"
description: "In order to build the container image, you’ll need to use a Dockerfile. A Dockerfile is simply a text-based file with no file extension. A Dockerfile contains a script of instructions that Docker uses to create a container image."
lead: "In order to build the container image, you’ll need to use a Dockerfile. A Dockerfile is simply a text-based file with no file extension. A Dockerfile contains a script of instructions that Docker uses to create a container image."
menu:
  docs:
    parent: "play-with-docker"
weight: 220
---

## Build the app's container image

Open the terminal and run the following commands listed below.

1. Change the direcotry to the home direcotry:
    ```sh
    cd
    ```

2. Clone the app repository and change the directory to the `app` directory:

    ```sh
    git clone https://github.com/docker/getting-started.git && cd getting-started/app
    ```

3. Create a file named `Dockerfile` with some content used to create the image:

    ```sh
    cat <<EOF | tee Dockerfile
    FROM node:18-alpine
    WORKDIR /app
    COPY . .
    RUN yarn install --production
    CMD ["node", "src/index.js"]
    EXPOSE 3000
    EOF
    ```

    * The [`FROM`](https://docs.docker.com/engine/reference/builder/#from) instruction initializes a new build stage and sets the Base Image for subsequent instructions. As such, a valid Dockerfile must start with a `FROM` instruction. The image can be any valid image – it is especially easy to start by pulling an image from the Public Repositories.

    * The [`WORKDIR`](https://docs.docker.com/engine/reference/builder/#workdir) instruction sets the working directory for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY` and `ADD` instructions that follow it in the `Dockerfile`.

    * The [`COPY`](https://docs.docker.com/engine/reference/builder/#copy) instruction copies new files or directories from `<src>` and adds them to the filesystem of the container at the path `<dest>`.

    * The [`RUN`](https://docs.docker.com/engine/reference/builder/#run) instruction will execute any commands in a new layer on top of the current image and commit the results. The resulting committed image will be used for the next step in the `Dockerfile`.

    * The main purpose of a [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd) is to provide defaults for an executing container. There can only be one `CMD` instruction in a `Dockerfile`. If you list more than one `CMD` then only the last `CMD` will take effect.
    
    * The [`EXPOSE`](https://docs.docker.com/engine/reference/builder/#expose) instruction informs Docker that the container listens on the specified network ports at runtime. __The `EXPOSE` instruction does not actually publish the port__. It functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.

4. Build the container image named `getting-started` starting from the current directory:

    ```sh
    docker build -t getting-started .
    ```

## Explore the image layers

```sh
docker history getting-started
```

The output shows all the layers of the image with their sizes.

## Start an app container

Now that you have an image, you can run the application in a container. To do so, you will use the docker run command.

1. Start your container using the docker run command and specify the name of the image you just created:

    ```sh
    docker run -d -p 8080:3000 getting-started
    ```

    You use the `-d` flag to run the new container in "detached" mode (in the background). You also use the `-p` flag to create a mapping between the host’s port `8080` to the container’s port `3000`. Without the port mapping, you wouldn’t be able to access the application even if you specified it in the `Dockerfile`.

2. After a few seconds, open your web browser to [`http://localhost:8080`](http://localhost:8080). You should see your app.

3. Go ahead and add an item or two and see that it works as you expect. You can mark items as complete and remove items. Your frontend is successfully storing items in the backend.

At this point, you should have a running todo list manager with a few items, all built by you.