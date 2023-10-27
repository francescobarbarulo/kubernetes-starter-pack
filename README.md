# Kubernetes Starter Pack

This material is tied to the Kubernetes Starter Pack course delivered by [EDU.labs](https://www.educationlabs.it/) by Computer Gross.

Start from [here](./guides/lab0.md)!

## Replicating the lab environment

You can replicate the lab on your own by using an Ubuntu 22.04 machine.

### Prerequisites

1. Install lxd.

    ```sh
    snap install lxd
    ```

2. Clone this repository.

    ```sh
    git clone https://github.com/francescobarbarulo/kubernetes-starter-pack.git
    ```

### Bootstrap lab

1. Change directory to `scripts/lxd`.

    ```sh
    cd kubernetes-starter-pack/scripts/lxd
    ```

2. Give execution permissions to the scripts.

    ```sh
    chmod u+x bootstrap.sh destroy.sh
    ```

3. Run the bootstrap script.

    ```sh
    ./bootstrap.sh
    ```

### Destroy lab

1. Run the destroy script.

    ```sh
    ./destroy
    ```