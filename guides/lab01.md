# Lab 01

In this lab you are going to install the Docker Engine, create and deploy a containerized application.

Open the terminal and run the following commands listed below.

## Install Docker Engine


1. Clone this repo on your local machine and change directory to it:

    ```sh
    git clone https://github.com/francescobarbarulo/kubernetes-starter-pack && cd kubernetes-starter-pack
    ```

2. Give the execution permission to all the scripts:

    ```sh
    sudo chmod +x scripts/*
    ```

3. Launch the installation script which will follow the [repository installation method](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository):

    ```sh
    ./scripts/docker-install.sh
    ```

    > ⚠️ Log out and log back in so that your group membership is re-evaluated

4. Verify that you can interact with the Docker Engine:

    ```sh
    docker ps
    ```

## Explore network interfaces

```sh
ip addr show
```

You should see a newly `docker0` interface with ip address `172.17.0.1/16` created by Docker. This is the virtual bridge used to forward data traffic to containers attached to it.

## Explore network routes

```sh
ip route
```

You should see a newly route created by Docker that states that all traffic directed to subnet `172.17.0.0/16` (where containers will reside by default; Docker daemon acts as a DHCP server) must go to the `docker0` interface.

## Build the app's container image

1. Clone the app repository and change the directory to the `app` directory:

    ```sh
    git clone https://github.com/docker/getting-started.git && cd getting-started/app
    ```

2. Create a file named `Dockerfile` with some content used to create the image:

    ```sh
    cat <<EOF | tee Dockerfile > /dev/null
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

3. Build the container image giving the name `getting-started` starting from the current directory (`.`):

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

## Update the source code

1. In the `src/static/js/app.js` file, update line 56 to use the new empty text:

    ```sh
    sed -i 's/No items yet! Add one above!/You have no todo items yet! Add one above!/' src/static/js/app.js
    ```

2. Build the updated version of the image using `docker build` command you used previosuly.

    ```sh
    docker build -t getting-started .
    ```

3. Start a new container using the new image.

    ```sh
    docker run -d -p 8080:3000 getting-started
    ```

    You probably saw an error like this (the IDs will be different):

    ```plaintext
    docker: Error response from daemon: driver failed programming external connectivity on endpoint laughing_burnell 
    (bb242b2ca4d67eba76e79474fb36bb5125708ebdabd7f45c8eaf16caaabde9dd): Bind for 0.0.0.0:3000 failed: port is already allocated.
    ```

    The error occurred because you aren’t able to start the new container while your old container is still running. The reason is that the old container is already using the host’s port `8080` and only one process on the machine (containers included) can listen to a specific port. To fix this, you need to remove the old container.

## Remove the old container

To remove a container, you first need to stop it. Once it has stopped, you can remove it.

1. Get the ID of the container by using the `docker ps` command.

    ```sh
    docker ps
    ```

2. Use the `docker stop` command to stop the container. Replace <the-container-id> with the ID from `docker ps`.

    ```sh
    docker stop <the-container-id>
    ```

3. You can show the stopped container by typing `docker ps -a`. You should see two stopped containers, the one stopped at step 2 and the one exited because of the port binding error.

4. Once the container is stopped, you can remove it by using the `docker rm` command.

    ```sh
    docker rm <the-container-id>
    ```

    **Remove both the stopped containers**.

    > 💡 You can stop and remove a container in a single command by adding the `force` flag to the `docker rm` command. For example: `docker rm -f <the-container-id>`.

5. You removed the old container, but the image from which it was originated is still present on the machine. List all the images. 

    ```sh
    docker images
    ```

    You should see the old image of your app represented by the `<none>` placeholder.

    ```plaintext
    REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
    <none>            <none>    c3de9545b495   30 minutes ago   262MB
    ```

6. Take note of the image ID and remove it.

    ```sh
    docker rmi <the-image-id>
    ```

## Start the updated app container

1. Now, start your updated app using the `docker run` command.

    ```sh
    docker run -d -p 8080:3000 getting-started
    ```

2. Refresh your browser on `http://localhost:8080` and you should see your updated help text.

## Next

[Lab 02](./lab02.md)