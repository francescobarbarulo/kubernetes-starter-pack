# Lab 0

The lab is composed by a single Ubuntu 22.04 virtual machine, from now on called *host* machine (`student@lab`).
On top of it you will find four different isolated environments:

| Environment | Shell | Description |
|---|---|---|
| `dev` | root@dev | Developer laptop |
| `registry` | root@registry | Private registry image |
| `k8s-cp-01` | root@k8s-cp-01 | Kubernetes control plane node |
| `k8s-w-01` | root@k8s-w-01 | Kubernetes worker node |

These environments are provided by means of Linux Containers (LXC).
Below some useful commands to interact with them.

**Note**: During the lab be careful to execute the commands in the right environment.

### List the environments
  ```sh
  lxc list
  ```
  > Refer to `eth0` interface for the IP address.

### Open a shell session inside an environment
  ```sh
  lxc exec <env> bash
  ```

### Pull a file from an environment to the `host`
  ```sh
  lxc file pull <env>:/<path> <host path>
  ```

## Next

[Lab 01](./lab01.md)