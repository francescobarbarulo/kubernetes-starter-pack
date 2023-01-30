---
title: "1. Install Docker"
description: "Install Docker Engine from Docker's apt repository and explore the Docker host."
lead: "Install Docker Engine from Docker's apt repository and explore the Docker host."
menu:
  docs:
    labs:
      parent: "play-with-docker"
weight: 210
---

## Install Docker Engine

Open the terminal and run the following commands listed below.

1. Change directory to the cloned repository directory:

    ```sh
    cd ~/k8slab
    ```

2. Give the execution permission to the installation script:

    ```sh
    sudo chmod +x lab/install/docker.sh
    ```

3. Launch the installation script which will follow the [repository installation method](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository):

    ```sh
    ./lab/install/docker.sh
    ```

{{< alert icon="💡" text="Log out and log back in so that your group membership is re-evaluated." />}}

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