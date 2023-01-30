---
title: "5. Persist the DB"
description: "In case you didn’t notice, our todo list is being wiped clean every single time we launch the container. Why is this? Let’s dive into how the container is working."
lead: "In case you didn’t notice, our todo list is being wiped clean every single time we launch the container. Why is this? Let’s dive into how the container is working."
menu:
  docs:
    parent: "play-with-docker"
weight: 250
---

## Container volumes

When a container runs, it uses the various layers from an image for its filesystem. Each container also gets its own "scratch space" to create/update/remove files. Any changes won’t be seen in another container, _even if_ they are using the same image.
Moreover, those changes are lost when the container is removed.

Volumes provide the ability to connect specific filesystem paths of the container back to the host machine. If a directory in the container is mounted, changes in that directory are also seen on the host machine. If we mount that same directory across container restarts, we’d see the same files.

## Persist the todo data

By default, the todo app stores its data in a SQLite Database at `/etc/todos/todo.db` in the container’s filesystem. If you’re not familiar with SQLite, no worries! It’s simply a relational database in which all of the data is stored in a single file. While this isn’t the best for large-scale applications, it works for small demos. We’ll talk about switching this to a different database engine later.

With the database being a single file, if we can persist that file on the host and make it available to the next container, it should be able to pick up where the last one left off. By creating a volume and attaching (often called "mounting") it to the directory the data is stored in, we can persist the data. As our container writes to the `todo.db` file, it will be persisted to the host in the volume.

As mentioned, we are going to use a named volume. Think of a named volume as simply a bucket of data. Docker maintains the physical location on the disk and you only need to remember the name of the volume. Every time you use the volume, Docker will make sure the correct data is provided.

1. Create a volume by using the docker volume create command.

    ```sh
    docker volume create todo-db
    ```

2. Stop and remove the todo app container once again with `docker rm -f <id>`, as it is still running without using the persistent volume.

3. Start the todo app container, but add the `-v` flag to specify a volume mount. We will use the named volume and mount it to `/etc/todos`, which will capture all files created at the path.

    ```sh
    docker run -d -p 8080:3000 -v todo-db:/etc/todos localhost:5000/getting-started
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
