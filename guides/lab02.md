# Lab 02

In this lab you are going to expose your application to be reachable outside the environment.
Then you will create and attach a volume to the database container to persist the todo list upon the container restarts.
Finally you will connect it to a containerized mysql database used to store the todo items.

Open a shell in the `dev` environment.
You should see something similar to this:

```plaintext
root@dev:~#
```

## Expose the application

1. Start the application container called `myapp-internal`, but this time adding the `-p` flag. The *publish* flag is used to create a mapping between the host's port `8080` to the container's port `3000`. Without the port mapping, you wouldn't be able to access the application even if you specified it in the `Dockerfile` with the `EXPOSE` instruction which only functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.

    ```sh
    docker run --name myapp-internal -d -p 8080:3000 getting-started:v1
    ```  

2. After a few seconds, open the web browser to `http://<dev>:8080` and you should see your app.
    
    **Tip**: Open another terminal window and run `lxc list`.

3. In the application add an item or two and see that it works as you expect. You can mark items as complete and remove items. Your frontend is successfully storing items in the backend.

## Update the source code

Make sure you came back to the `dev` environment (`root@dev`).

1. In the `src/static/js/app.js` file, update line 56 to use the new empty text:

    ```sh
    sed -i 's/No items yet! Add one above!/You have no todo items yet! Add one above!/' src/static/js/app.js
    ```

2. Build the updated version of the image with the `v2` tag using `docker build` command you used previosuly.

    ```sh
    docker build -t getting-started:v2 .
    ```

3. Start a new container using the new image.

    ```sh
    docker run -d -p 8080:3000 getting-started:v2
    ```

    You probably saw an error like this (the IDs will be different):

    ```plaintext
    docker: Error response from daemon: driver failed programming external connectivity on endpoint laughing_burnell 
    (bb242b2ca4d67eba76e79474fb36bb5125708ebdabd7f45c8eaf16caaabde9dd): Bind for 0.0.0.0:3000 failed: port is already allocated.
    ```

    The error occurred because you aren’t able to start the new container while your old container is still running. The reason is that the old container is already using the host’s port `8080` and only one process on the machine (containers included) can listen to a specific port. To fix this, you need to remove the old container.

## Challenge 02

Stop and remove the old container, start again the new one with port mapping and name `myapp-external`, and verify it is up and running.

<details>
  <summary>Solution</summary>

  1. Remove the `myapp-internal` container.

        ```sh
        docker stop myapp-internal
        docker rm myapp-internal
        ```

        > A container can be removed only if it is previously stopped. You can use `docker rm -f <container-id>` to force the deletion even if the container is running.

  2. Start the new container.

        ```sh
        docker run --name myapp-external -d -p 8080:3000 getting-started:v2
        ```

</details>

## Persist the todo data

When a container runs, it uses the various layers from an image for its filesystem. Each container also gets its own "scratch space" to create/update/remove files. Any changes won’t be seen in another container, _even if_ they are using the same image.
Moreover, those changes are lost when the container is removed.

Volumes provide the ability to connect specific filesystem paths of the container back to the host machine. If a directory in the container is mounted, changes in that directory are also seen on the host machine. If you mount that same directory across container restarts, you’d see the same files.

By default, the todo app stores its data in a SQLite Database at `/etc/todos/todo.db` in the container’s filesystem. If you’re not familiar with SQLite, no worries! It’s simply a relational database in which all of the data is stored in a single file. While this isn’t the best for large-scale applications, it works for small demos. You’ll talk about switching this to a different database engine later.

With the database being a single file, if you can persist that file on the host and make it available to the next container, it should be able to pick up where the last one left off. By creating a volume and attaching (often called "mounting") it to the directory the data is stored in, you can persist the data. As our container writes to the `todo.db` file, it will be persisted to the host in the volume.

As mentioned, you are going to use a named volume. Think of a named volume as simply a bucket of data. Docker maintains the physical location on the disk and you only need to remember the name of the volume. Every time you use the volume, Docker will make sure the correct data is provided.

1. Create a volume by using the docker volume create command.

    ```sh
    docker volume create todo-db
    ```

2. Stop and remove the todo app container once again as it is still running without using the persistent volume.

    ```sh
    docker rm -f myapp-external
    ```

3. Start the todo app container, but add the `-v` flag to specify a volume mount. You will use the named volume and mount it to `/etc/todos`, which will capture all files created at the path.

    ```sh
    docker run --name myapp-external -d -p 8080:3000 -v todo-db:/etc/todos getting-started:v2
    ```

4. Once the container starts up, open the app and add a few items to your todo list.

5. Stop and remove the container for the todo app.

6. Start a new container using the same command from above. What do you expect? Open the app and you should see your items still in your list!

7. Go ahead and remove the container when you’re done checking out your list.

Hooray! You’ve now learned how to persist data!

## Dive into the volume

A lot of people frequently ask "Where is Docker actually storing my data when I use a named volume?" If you want to know, you can use the docker volume inspect command.

```sh
docker volume inspect todo-db
```

The `Mountpoint` is the actual location on the disk where the data is stored. Note that on most machines, you will need to have root access to access this directory from the host. But, that’s where it is!

## Container Networking

Remember that containers, by default, run in isolation and don’t know anything about other processes or containers on the same machine. So, how do you allow one container to talk to another? The answer is networking. Now, you don’t have to be a network engineer (hooray!). Simply remember this rule...

> If two containers are on the same network, they can talk to each other. If they aren't, they can't.

## Start MySQL

There are two ways to put a container on a network: (i) Assign it at start or (ii) connect an existing container. For now, you will create the network first and attach the MySQL container at startup.

1. Create the network.
    
    ```sh
    docker network create todo-app
    ```

2. Start a MySQL container and attach it to the network. You're also going to define a few environment variables that the database will use to initialize the database (see the "Environment Variables" section in the MySQL Docker Hub listing).

    ```sh
    docker run -d \
      --network todo-app --network-alias mysql \
      -v todo-mysql-data:/var/lib/mysql \
      -e MYSQL_ROOT_PASSWORD=secret \
      -e MYSQL_DATABASE=todos \
      mysql:8.0
    ```

    You'll also see you specified the `--network-alias` flag. You'll come back to that in just a moment.

    > You'll notice you're using a volume named `todo-mysql-data` here and mounting it at `/var/lib/mysql`, which is where MySQL stores its data. However, you never ran a docker volume create command. Docker recognizes you want to use a named volume and creates one automatically for us.


3. To confirm you have the database up and running, connect to the database and verify it connects.

    ```sh
    docker exec -it <mysql-container-id> mysql -u root -p
    ```

    When the password prompt comes up, type in __secret__. In the MySQL shell, list the databases and verify you see the `todos` database.

    ```mysql
    SHOW DATABASES;
    ```

    You should see output that looks like this:

    ```plaintext
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    | todos              |
    +--------------------+
    5 rows in set (0.00 sec)
    ```

    Exit the MySQL shell to return to the shell on our machine.

    ```mysql
    exit
    ```

    Hooray! You have our todos database and it’s ready for us to use!

## Run your app with MySQL

The todo app supports the setting of a few environment variables to specify MySQL connection settings. They are:

* `MYSQL_HOST` - the hostname for the running MySQL server
* `MYSQL_USER` - the username to use for the connection
* `MYSQL_PASSWORD` - the password to use for the connection
* `MYSQL_DB` - the database to use once connected

Let's connect the todo app to MySQL.

1. You'll specify each of the environment variables above with the `-e` flag, as well as connect the container to the app network.

    ```sh
    docker run -d -p 8080:3000 \
      --network todo-app \
      -e MYSQL_HOST=mysql \
      -e MYSQL_USER=root \
      -e MYSQL_PASSWORD=secret \
      -e MYSQL_DB=todos \
      localhost:5000/getting-started:v2
    ```

    > You'll notice you're using the value `mysql` as `MYSQL_HOST`. While `mysql` isn't normally a valid hostname, Docker is able to resolve it to the IP address of the mysql container thanks to the `--network-alias` flag.

2. If you look at the logs for the container (`docker logs -f <container-id>`), you should see a message indicating it's using the mysql database.

    ```plaintext
    Connected to mysql db at host mysql
    Listening on port 3000
    ```

3. Open the app in your browser and add a few items to your todo list.

4. Connect to the mysql database and prove that the items are being written to the database. Remember, the password is __secret__.

    ```sh
    docker exec -it <mysql-container-id> mysql -p todos
    ```

    And in the mysql shell, run the following:

    ```mysql
    select * from todo_items;
    ```

    You should see your items listed in the output table.

    Exit the MySQL shell to return to the shell on our machine.

    ```mysql
    exit
    ```

## Next

[Lab 03](./lab03.md)