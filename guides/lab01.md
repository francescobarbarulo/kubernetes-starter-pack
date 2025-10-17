# Lab 01

In this lab you are going to install the Docker Engine, run some containers based on images publicly available on Docker Hub, and create your own container image.

## Install Docker Engine

🖥️ Open a shell in the `dev` environment.

1. Launch the installation script which will follow the [repository installation method](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository):

   ```sh
   curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/docker-install.sh | sh
   ```

## Run your first container

Now you are ready to run your first container using the Docker CLI.

🖥️ Open a shell in the `dev` environment.

1. Pull the `hello-world` image from the Docker Hub. Remember that if you do not specify the registry endpoint before the image name, Docker will pull the image from the default registry (`registry-1.docker.io`).

   ```sh
   docker pull hello-world
   ```

2. Verify the image has been pulled successfully.

   ```sh
   docker images
   ```

   The output is similar to this:

   ```plaintext
   REPOSITORY    TAG       IMAGE ID       CREATED       SIZE
   hello-world   latest    9c7a54a9a43c   6 weeks ago   13.3kB
   ```

3. Start your first container from the `hello-world` image specifying the container name by using `--name` flag.

   ```sh
   docker run --name hello hello-world
   ```

   > If you do not specify the container name, Docker will randomly assign one.

4. Verify your container is up and running.

   ```sh
   docker ps
   ```

   The output shows all running containers. As you see, there are not any containers up and running. This because the `hello` container is not a service that continuously runs, but it prints a message and exits.

5. You can list all containers, independently of their state, by adding the `-a` flag.

   ```sh
   docker ps -a
   ```

   The output is similar to this:

   ```plaintext
   CONTAINER ID   IMAGE         COMMAND    CREATED         STATUS                     PORTS     NAMES
   5a33397462e6   hello-world   "/hello"   7 minutes ago   Exited (0) 7 minutes ago             hello
   ```

   The `hello` container is identified by a container ID (`5a33397462e6`) and is in the `Exited` status.

6. Let's run the `httpd` image that starts an apache HTTP server. You are going to specify the image version by adding the tag (`:2.4`).

   ```sh
   docker run --name apache httpd:2.4
   ```

   > The `run` command automatically pulls the image if it is not found locally. In general, there is no need to pull the image before running the container.

   By default, `docker run` can start the process in the container and attach the console to the process’s standard input, output, and standard error.
   Usually containers are started in detached mode, so that you can get back the shell.

7. Terminate the containerized process by pressing `Ctrl+C`.

8. Start again the apache container, but in the detached mode by adding the `-d` flag.

   ```sh
   docker run --name apache -d httpd:2.4
   ```

   You should see an error like the following:

   ```plaintext
   docker: Error response from daemon: Conflict. The container name "/apache" is already in use by container "70887675d3d18206298b609d570bff9afaf90462c4ad7dfd7489a2e6e73b0959". You have to remove (or rename) that container to be able to reuse that name.
   ```

   **Note**: You can not run two containers with the same name.

9. Remove the old exited apache container.

   ```sh
   docker rm apache
   ```

   > You can remove a container by specifiying either the name or the container id.

10. Try to run apache container in detached mode.

    ```sh
    docker run --name apache -d httpd:2.4
    ```

    The output represents the container ID and it should be something like this:

    ```plaintext
    ee13332c801e4f4ecaa8ecdf585faa95b5bae398fccb34d63e7ad9a077ae5a06
    ```

## Build you own container image

Assume you have a project codebase hosted on some version control hosting platform like GitHub.

🖥️ Open a shell in the `dev` environment.

1. Clone the app repository and change the directory to the `app` directory.

   ```sh
   git clone https://github.com/docker/getting-started.git && cd getting-started/app
   ```

2. Create a file named `Dockerfile` with some content used to create the image. The app is a NodeJS app.

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

   - The [`FROM`](https://docs.docker.com/engine/reference/builder/#from) instruction initializes a new build stage and sets the Base Image for subsequent instructions. As such, a valid Dockerfile must start with a `FROM` instruction. The image can be any valid image – it is especially easy to start by pulling an image from the public repositories.

   - The [`WORKDIR`](https://docs.docker.com/engine/reference/builder/#workdir) instruction sets the working directory in the _image_ filesystem for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY` and `ADD` instructions that follow it in the `Dockerfile`.

   - The [`COPY`](https://docs.docker.com/engine/reference/builder/#copy) instruction copies new files or directories from local filesystem at path `<src>` and adds them to the filesystem of the container at the path `<dest>`.

   - The [`RUN`](https://docs.docker.com/engine/reference/builder/#run) instruction will execute any commands in a new layer on top of the current image and commit the results. The resulting committed image will be used for the next step in the `Dockerfile`.

   - The main purpose of a [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd) is to provide defaults for an executing container. There can only be one `CMD` instruction in a `Dockerfile`. If you list more than one `CMD` then only the last `CMD` will take effect.

   - The [`EXPOSE`](https://docs.docker.com/engine/reference/builder/#expose) instruction informs Docker that the container listens on the specified network ports at runtime. **The `EXPOSE` instruction does not actually publish the port**. It functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.

3. Build the container image giving the name and tag `getting-started:v1` taking in consideration the current directory (`.`).

   ```sh
   docker build -t getting-started:v1 .
   ```

## Explore the image layers

🖥️ Open a shell in the `dev` environment.

1. View all the layers of the image with their sizes, including the ones belonging to the base image `node:18-alpine`.

   ```sh
   docker history getting-started:v1
   ```

## Challenge 01

Start the application container with name `myapp`, in detached mode, and verify it is up and running.
Then stop and remove the `myapp` container.

**Tip**: Run `docker --help` to show all the docker commands.

<details>
	<summary>Solution</summary>

1. Start `myapp` container.

   ```sh
   docker run -d --name myapp getting-started:v1
   ```

   The output is similar to this:

   ```plaintext
   CONTAINER ID   IMAGE                COMMAND                  CREATED         STATUS         PORTS      NAMES
   bb9c561081a8   getting-started:v1   "docker-entrypoint.s…"   4 seconds ago   Up 3 seconds   3000/tcp   myapp
   d082554ae65f   httpd:2.4            "httpd-foreground"       2 days ago      Up 3 minutes   80/tcp     apache
   ```

   At the moment you are not able to access the appication from the browser outside the environment.

2. Stop the `myapp` container.

   ```sh
   docker stop myapp
   ```

3. Remove the `myapp` container.

   ```sh
   docker rm myapp
   ```

   > A container can be removed only if it has been previously stopped.

</details>

## Next

[Lab 02](./lab02.md)
