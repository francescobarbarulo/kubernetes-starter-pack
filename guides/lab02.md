# Lab 02

In this lab you are going to push the container image to a private registry deployed as containerized service on your host.
Then you will pull and run your container image exploiting volumes to persist the todo list upon container restart.
Finally you will use a mysql database to store the todo items and you will connect to it from the application using a docker network.

Open the terminal and run the following commands listed below.

## Deploy the registry server

Docker provides a containerized local registry that can be started using the `docker run` command. You will also configure the registry server by providing native basic authentication.

1. Create a password file with one entry for the user `testuser`, with password `testpassword`:
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

3. After a few seconds, open your web browser at [`http://localhost:5000/v2/_catalog`](http://localhost:5000/v2/_catalog). Use the above credentials when requested. You should see an empty json response `{"repositories":[]}`.

## Push the image

1. In the command line, try running the push command:
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
    docker tag getting-started:v2 localhost:5000/getting-started:v2
    ```

3. Before pushing the renamed image, login to the local registry using `testpassword` as password when prompted.

    ```sh
    docker login localhost:5000 -u testuser
    ```

4. Now try to push again.

    ```sh
    docker push localhost:5000/getting-started:v2
    ```

5. Check the image is present on the registry by refreshing the web browser at [`http://localhost:5000/v2/_catalog`](http://localhost:5000/v2/_catalog). You should see a json response like this: `{"repositories":["getting-started"]}`. 

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

3. Use the `docker rmi`command to remove all the images:

    ```sh
    docker rmi localhost:5000/getting-started:v2 getting-started:v2 getting-started:v1
    ```

4. Now that the `getting-started` image is not present on your machine, you need to pull it from the local registry. This is done automatically with the `docker run` command:

    ```sh
    docker run -d -p 8080:3000 localhost:5000/getting-started:v2
    ```

    You should see the image get pulled down and eventually start up!

5. Reopen your web browser to [`http://localhost:8080`](http://localhost:8080) and check if it works.

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

2. Stop and remove the todo app container once again with `docker rm -f <id>`, as it is still running without using the persistent volume.

3. Start the todo app container, but add the `-v` flag to specify a volume mount. You will use the named volume and mount it to `/etc/todos`, which will capture all files created at the path.

    ```sh
    docker run -d -p 8080:3000 -v todo-db:/etc/todos localhost:5000/getting-started:v2
    ```

4. Once the container starts up, open the app and add a few items to your todo list.

5. Stop and remove the container for the todo app. Use `docker ps` to get the ID and then `docker rm -f <id>` to remove it.

6. Start a new container using the same command from above.

7. Open the app. You should see your items still in your list!

8. Go ahead and remove the container when you’re done checking out your list.

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

1. You'll specify each of the environment variables above, as well as connect the container to our app network.

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

## Clean up

1. Get the root privileges and launch the script.

    ```sh
    sudo su -
    ```

2. Uninstall docker:

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/docker-uninstall.sh | sh
    ```

3. Exit the root shell.

    ```sh
    exit
    ```

4. Remove the current user from docker group and delete the docker group.

    ```sh
    sudo deluser $USER docker
    ```

5. Log out and log back in so that your group membership is re-evaluated.


## Next

[Lab 03](./lab03.md)