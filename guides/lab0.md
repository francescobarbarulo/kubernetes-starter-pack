# Lab 0

The lab environment is composed by a single Ubuntu 22.04 virtual machine.
On top of it you will find four different isolated environments:

* `dev`: the developer laptop
* `registry`: the private image registry
* `k8s-cp-01`: a Kubernetes control plane node
* `k8s-w-01`: a Kubernetes worker node

These environments are provided by leveraing Linux Containers (LXC).
Below some useful commands to interact with them:

* List the environments with their IP addresses (refer to `eth0`):
  ```sh
  lxc list
  ```

* Create a shell session inside an environment:
  ```sh
  lxc exec <env> bash
  ```

* Pull a file from an environment to the host:
  ```sh
  lxc file pull <env>:/<path> <host path>
  ```

**Note**: During the lab be careful to execute the commands in the right environment.