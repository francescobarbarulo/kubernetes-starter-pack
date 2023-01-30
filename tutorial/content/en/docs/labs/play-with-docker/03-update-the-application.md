---
title: "3. Update the application"
description: "In this part, you will update the application and container image. You will also learn how to stop and remove a container."
lead: "In this part, you will update the application and container image. You will also learn how to stop and remove a container."
menu:
  docs:
    parent: "play-with-docker"
weight: 230
---

## Update the source code

Open the terminal and run the following commands listed below.

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

The error occurred because you aren’t able to start the new container while your old container is still running. The reason is that the old container is already using the host’s port 8080 and only one process on the machine (containers included) can listen to a specific port. To fix this, you need to remove the old container.

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

3. Once the container is stopped, you can remove it by using the `docker rm` command.

    ```sh
    docker rm <the-container-id>
    ```

{{< alert context="info">}}
You can stop and remove a container in a single command by adding the `force` flag to the `docker rm` command.
For example: `docker rm -f <the-containr-id>`
{{< /alert >}}

## Start the updated app container

1. Now, start your updated app using the `docker run` command.

    ```sh
    docker run -d -p 8080:3000 getting-started
    ```

2. Refresh your browser on `http://localhost:8080` and you should see your updated help text.