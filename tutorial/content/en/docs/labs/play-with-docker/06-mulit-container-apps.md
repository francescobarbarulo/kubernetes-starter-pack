---
title: "6. Multi-container apps"
description: "Up to this point, we have been working with single container apps. But, we now want to add MySQL to the application stack."
lead: "Up to this point, we have been working with single container apps. But, we now want to add MySQL to the application stack."
menu:
  docs:
    parent: "play-with-docker"
weight: 260
---

## Container Networking

Remember that containers, by default, run in isolation and don’t know anything about other processes or containers on the same machine. So, how do we allow one container to talk to another? The answer is networking. Now, you don’t have to be a network engineer (hooray!). Simply remember this rule...

{{< alert context="info" text="If two containers are on the same network, they can talk to each other. If they aren't, they can't." />}}

## Start MySQL

There are two ways to put a container on a network: 1) Assign it at start or 2) connect an existing container. For now, we will create the network first and attach the MySQL container at startup.

1. Create the network.
    
    ```sh
    docker network create todo-app
    ```

2. Start a MySQL container and attach it to the network. We're also going to define a few environment variables that the database will use to initialize the database (see the "Environment Variables" section in the MySQL Docker Hub listing).

    ```sh
    docker run -d \
      --network todo-app --network-alias mysql \
      -v todo-mysql-data:/var/lib/mysql \
      -e MYSQL_ROOT_PASSWORD=secret \
      -e MYSQL_DATABASE=todos \
      mysql:8.0
    ```

    You'll also see we specified the `--network-alias` flag. We'll come back to that in just a moment.

{{< alert context="info" >}}
You'll notice we're using a volume named `todo-mysql-data` here and mounting it at `/var/lib/mysql`, which is where MySQL stores its data. However, we never ran a docker volume create command. Docker recognizes we want to use a named volume and creates one automatically for us.
{{< /alert >}}


3. To confirm we have the database up and running, connect to the database and verify it connects.

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

    Hooray! We have our todos database and it’s ready for us to use!

## Run your app with MySQL

The todo app supports the setting of a few environment variables to specify MySQL connection settings. They are:

* `MYSQL_HOST` - the hostname for the running MySQL server
* `MYSQL_USER` - the username to use for the connection
* `MYSQL_PASSWORD` - the password to use for the connection
* `MYSQL_DB` - the database to use once connected

Let's connect the todo app to MySQL

1. We'll specify each of the environment variables above, as well as connect the container to our app network.

    ```sh
    docker run -d -p 8080:3000 \
      --network todo-app \
      -e MYSQL_HOST=mysql \
      -e MYSQL_USER=root \
      -e MYSQL_PASSWORD=secret \
      -e MYSQL_DB=todos \
      getting-started
    ```

{{< alert context="info" >}}
You'll notice we're using the value `mysql` as `MYSQL_HOST`. While `mysql` isn't normally a valid hostname, Docker is able to resolve it to the IP address of the mysql container thanks to the `--network-alias` flag.
{{< /alert >}}

2. If we look at the logs for the container (`docker logs -f <container-id>`), we should see a message indicating it's using the mysql database.

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