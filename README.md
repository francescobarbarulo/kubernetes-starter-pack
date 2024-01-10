# Kubernetes Starter Pack

This material is tied to the Kubernetes Starter Pack course delivered by [EDU.labs](https://www.educationlabs.it/) by Computer Gross.

Start from [here](./guides/lab0.md)!

## Replicating the lab environment

You can replicate the lab on your own by using an Ubuntu 22.04 machine.

### Prerequisites

1. Install [Incus](https://linuxcontainers.org/incus/docs/main/).

    ```sh
    curl -sL https://raw.githubusercontent.com/francescobarbarulo/kubernetes-starter-pack/main/scripts/lab/incus-install.sh | sh
    ```

2. Clone this repository.

    ```sh
    git clone https://github.com/francescobarbarulo/kubernetes-starter-pack.git && cd kubernetes-starter-pack
    ```
3. Give execution permissions to the scripts.

    ```sh
    chmod +x scripts/lab/bootstrap.sh scripts/lab/destroy.sh
    ```

### Bootstrap lab

Run the bootstrap script.

  ```sh
  ./scripts/lab/bootstrap.sh
  ```

### Destroy lab

Run the destroy script.

  ```sh
  ./scripts/lab/destroy.sh
  ```