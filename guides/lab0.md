# Lab 0

The lab is composed by a dedicated Ubuntu 22.04 virtual machine, from now on called `student` machine (`student@lab`).
On top of it you will find six different isolated environments provided by means of Linux Containers (LXC). Nevertheless you can think of them as physical or virtual machines:

| Environment | Shell | Description | IP address | 
|---|---|---|---|
| `dev` | `root@dev` | Developer laptop | `172.30.10.10` |
| `registry` | `root@registry` | Private image registry host | `172.30.10.11` |
| `nfs` | `root@nfs` | NFS server | `172.30.10.12` |
| `k8s-cp-01` | `root@k8s-cp-01` | Kubernetes control-plane node | `172.30.10.20` |
| `k8s-w-01` | `root@k8s-w-01` | Kubernetes worker node | `172.30.10.21` |
| `k8s-w-02` | `root@k8s-w-02` | Kubernetes worker node | `172.30.10.22` |

![Lab](./img/lab0/lab.svg "Lab environment")

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
  > It acts as `scp`

## Notes

* During the lab, be careful to execute the commands provided in the guides in the right environment. When you find a monitor emoji (🖥️) you are required to switch environment.

* When you find a string between angle brackets (e.g. `<something>`), you need to replace it with the right value, hopefully self-explanatory.

## Next

[Lab 01](./lab01.md)