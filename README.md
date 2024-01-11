# Kubernetes Starter Pack

This material is tied to the Kubernetes Starter Pack course delivered by [EDU.labs](https://www.educationlabs.it/) by Computer Gross.

Start from [here](./guides/lab0.md)!

## Replicating the lab environment

You can replicate the lab on your own by using an Ubuntu 22.04 or Debian 12 machine.

### Prerequisites

1. Install [Incus](https://linuxcontainers.org/incus/docs/main/).

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/incus-install.sh | sudo sh
    ```

2. Add your user to the `incus-admin` group in order to control incus without root privileges.

    ```sh
    sudo adduser $USER incus-admin
    ```

3. Logout and login again to restart the session.

### Bootstrap lab

Run the bootstrap script.

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/bootstrap.sh | sudo sh
  ```

### Destroy lab

Run the destroy script.

  ```sh
  curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/destroy.sh | sudo sh
  ```