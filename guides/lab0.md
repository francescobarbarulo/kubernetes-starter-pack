# Lab 0

The lab is composed by a dedicated VM, from now on called `student` machine (`student@lab`), on top of which you can find six different isolated environments provided by means of Linux Containers (LXC). Nevertheless you can think of them as physical or virtual machines:

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
  incus list
  ```
  > Refer to `eth0` interface for the IP address.

* Open a shell session inside an environment.
  ```sh
  incus exec <env> bash
  ```
  > It acts as `ssh`

* Pull a file from an environment to the `student` machine.
  ```sh
  incus file pull <env>/<path> <student host path>
  ```
  > It acts as `scp`

## Notes

* During the lab, be careful to execute the commands provided in the guides in the right environment. It is always specified at the beginning of each section by a monitor emoji (🖥️).

* When you find a string between angle brackets (e.g. `<something>`), hopefully self-explanatory, you need to replace it with the right value.

## Next

[Lab 01](./lab01.md)