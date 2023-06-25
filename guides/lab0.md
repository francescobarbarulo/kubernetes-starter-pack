# Lab 0

The lab is composed by a single Ubuntu 22.04 virtual machine, from now on called `student` machine (`student@lab`).
On top of it you will find four different isolated environments:

| Environment | Shell | Description |
|---|---|---|
| `dev` | `root@dev` | Developer laptop |
| `registry` | `root@registry` | Private image registry host |
| `nfs` | `root@nfs` | NFS server |
| `k8s-cp-01` | `root@k8s-cp-01` | Kubernetes control-plane node |
| `k8s-w-01` | `root@k8s-w-01` | Kubernetes worker node |

These environments are provided by means of Linux Containers (LXC). Nevertheless you can think of them as physical or virtual machines.

![Lab](./img/lab.svg "Lab environment")

## Commands to interact with the environments

* List the environments.
  ```sh
  lxc list
  ```
  > Refer to `eth0` interface for the IP address.

* Open a shell session inside an environment.
  ```sh
  lxc exec <env> bash
  ```
  > It acts as `ssh`

* Pull a file from an environment to the `student` machine.
  ```sh
  lxc file pull <env>/<path> <student host path>
  ```

## Notes

* During the lab, be careful to execute the commands provided in the guides in the right environment.

* When you find a string between angle brackets, you need to replace it with the right value, usually self-explanatory.

## Next

[Lab 01](./lab01.md)