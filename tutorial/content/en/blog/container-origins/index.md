---
title: "Container Origins"
description: "The \"container\" terminology is relatively new. You probably heard of it in combination with the word Docker. Maybe you have experience in creating a container with docker run. But how does Docker create containers for us?"
excerpt: "The \"container\" terminology is relatively new. You probably heard of it in combination with the word Docker. Maybe you have experience in creating a container with docker run. But how does Docker create containers for us?"
date: 2022-11-04T09:19:42+01:00
lastmod: 2022-11-04T09:19:42+01:00
draft: false
weight: 50
images: ["anatomy-of-shipping-container.jpg"]
categories: ["Tech"]
tags: ["linux", "containers", "cloud native"]
contributors: ["Francesco Barbarulo"]
pinned: false
homepage: false
---

The “container” terminology is relatively new. You probably heard of it in combination with the word *Docker*. Maybe you have experience in creating a container with `docker run`. But how does Docker create containers for us? I reveal you a secret: Docker eases the container management by leveraging **kernel features**. Yes, Docker branded something that was already existing in the Linux kernel, making containers popular and defining a new standard for **software distribution**.

For the moment let’s take apart Docker because here we are going to know which kernel features Docker employs behind the scenes. Let’s dive in by creating a container by hand.

## Prerequisites

If you are interested in replicating the commands in the snippets below you need a Linux OS, since it is commonly used in this area and most suitable to host containers, with Python installed. To create a Linux machine you could create a virtual environment with [Vagrant](https://www.vagrantup.com/intro).

## Base concept

Containers are intended to create a **lightweight** execution environment (*lightweight virtualization*) for services and applications that do not require the virtualization of an entire system (*full virtualization*) still ensuring isolation, dynamic instantiation and self-contained environment.

The concept of isolating portions of Linux kernel was conceived in Version 7 Unix (1979) with the introduction of the `chroot` system call. `chroot` changes the apparent view of the file system for the current process and all its children. The chroot’ed process is *jailed* in a specified root directory and cannot see anything else of the real file system. Let’s see how it works.

First create a fake root directory called `rootfs`, in which we are going to put the ubuntu base file system (we can choose our preferred one). **NOTE**: We are **not** downloading the full OS, just libraries and programs natively present in the OS distribution.

```bash
mkdir rootfs
# choose an ubuntu version
VERSION=22.04
curl -sLO http://cdimage.ubuntu.com/ubuntu-base/releases/$VERSION/release/ubuntu-base-$VERSION-base-amd64.tar.gz
# untar in rootfs
tar -xzf ubuntu-base-$VERSION-base-amd64.tar.gz -C rootfs
```

If we inspect the `rootfs` directory we can recognize the standard Linux file system structure. We have something like ubuntu in our OS with just one kernel!

Let’s put a placeholder to recognize it later:

```bash
touch rootfs/I_AM_UBUNTU_ROOTFS
```

Let’s start a new shell process (`/bin/bash`) inside ubuntu:

```bash
sudo chroot rootfs /bin/bash
# it should prompt something like root@workstation:/#
```

Now the process shell thinks that its root directory is `rootfs`. If we do an `ls /`  we should see the file we created. The process is isolated at the file system level.

Now, if we list the running processes with `ps aux` (first mount the `proc` file system with `mount -t proc proc /proc`), the chroot’ed shell process can still see all the processes in the system (we could kill any of it from the “container” 🤫).

With the term “container”, as it is used today, we refer to an **isolated environment** in which any process executed in it has an unique restricted view not only of the file system, but of any system entities, just like having a virtual machine. Processes inside a container are normal processes running on the kernel host, but they think they are only ones running on the machine.

A container only lives as long as the process inside is running. To stop our container just stop the shell process by exiting it typing `exit`.

## Namespaces

*Namespaces* (”the chroot for other resources”) fill the gap providing unique views for resources like process trees (PID), network interfaces (NET), volume mounts (MNT), etc. This feature was originated in 2002 in the 2.4.19 kernel with the mount namespace.

Namespaces can be created by using the `unshare` system call. With `unshare` bash utility, the new forked child will belong to the new specified namespaces. Let’s isolate our shell process even from the process tree perspective by creating a new PID namespace (`-p` or `--pid`) forking the new process (`-f` or `--fork`), mounting the `proc` file system and changing the root to the `rootfs`:

```bash
sudo unshare -p --mount-proc=$PWD/rootfs/proc -f chroot rootfs /bin/bash
```

⚠️ If the above command returns an `Invalid argument` error, you need to mount first the `rootfs/proc` directory by `mount -t proc proc rootfs/proc`.


Now, if we do `ps aux` we should see only two processes: the shell and the `ps` just issued. Moreover, the `/bin/bash` process has PID 1, which normally corresponds to the Linux init process, the ancestor of all processes running on the host. What the hell is that?! It seems we have two processes with the same PID in our system 🤯.

Let’s open another terminal to inspect what the system sees. If we do `ps aux` we should see all our running processes, including the `/bin/bash` launched in the "container" (**tip**: `ps aux | grep /bin/bash`), which, in this case, has a PID different from 1. When a new process namespace is created, the system creates an unique mapping between that namespace and the system one. The PID 1 in the container is associated to the first process launched with the `unshare`.

Exit the “container” by typing `exit`.

## Control groups (cgroups)

With namespaces we are able to restrict a process view, but not to limit the resource consumption by a process. Namespaced processes could still interfere with the whole system by abusing system resources, e.g. allocating to much memory, using to much CPU time, or disk and network bandwidth.

*Control groups* are used to control the amount of resources a process can use. Currently two cgroup implementations exist in Linux, v1 and v2. The snippets below refer to *cgroup v2*.

Cgroups are organized in a tree-shaped hierarchy, managed via a pseudo-filesystem using a special directory called `/sys/fs/cgroup`. All threads of a process belongs to the same cgroup. Children of a process belong to the parent’s cgroup, but they can be migrated to another cgroup. Initially, only the root cgroup exists in the system to which all process belongs. A child group can be created by creating a sub-directory.

Let’s create a `demo` cgroup:

```bash
sudo mkdir /sys/fs/cgroup/demo
```

The kernel automatically populates the `demo` cgroup directory with a bunch of files that are used to control that particular cgroup. We can add the current shell process to the `demo` cgroup by:

```bash
# first become root
sudo su
# add the current process ($$) to the demo cgroup
echo $$ > /sys/fs/cgroup/demo/cgroup.procs
# check the process's group membership
cat /proc/self/cgroup
# you should see 0::/demo
```

### Limit the number of PIDs

In this case we are going to limit the number of processes that can be forked by the current process. We are going to test the cgroup with a *fork bomb* attack wherein a process continually replicates itself to deplete available system resources, slowing down or crashing the system due to resource starvation. First we set the max number of processes to a reasonable value (in our case `5`) to mitigate this type of attack.

```bash
echo 5 > /sys/fs/cgroup/demo/pids.max
```

Then we can *safely* launch the fork bomb 🤞:

```bash
:(){ :|:& };:
```

If the cgroup is doing its job you should see the message `Resource temporarily unavailable`, and the machine should stay available because the fork bomb is constrained by the cgroup. After some time the system should kill all defunct forked processes.

To see the current number of processes:

```bash
watch cat /sys/fs/cgroups/demo/pids.current
```

### Limit memory usage

In this case we are going to limit the amount of memory the current process can use by setting it to 100MB. In order to see the effect of the cgroup we also need to disable the swap.

```bash
# disable swap for the demo cgroup
echo 0 > /sys/fs/cgroup/demo/memory.swap.max
# limit memory usage to 100mb
echo 100000000 > /sys/fs/cgroup/demo/memory.max
```

Then launch the following python script that starts eating memory:

```python
# hungry.py
def main():
  f = open("/dev/urandom", "r", encoding="ISO-8859-1")
  data = ""

  i=0
  while True:
    data += f.read(10000000) # 10mb
    i += 1
    print(f"{10*i}mb")

if __name__ == "__main__":
  main()
```

**NOTE**: When we issue the following command, a new python process is forked from the parent shell process inheriting its cgroup.

```bash
python3 hungry.py
```

If the cgroup is doing its job you should see an output like the following:

```bash
10mb
20mb
30mb
40mb
50mb
60mb
Killed
```

### Cleanup

- Delete the demo cgroup by removing the `/sys/fs/cgroup/demo` directory:
    
    ```bash
    # inside the container
    exit
    # outside the dead container
    sudo rmdir /sys/fs/cgroup/demo
    ```
    
- Unmount the `rootfs/proc` directory.
    
    ```bash
    sudo umount rootfs/proc
    ```
    
- Remove the `rootfs` directory:
    
    ```bash
    rmdir rootfs
    ```
    

## Summarizing

Containers are isolated environments that share the **same** kernel. Containers are **not meant** to run an operating system. The isolation is provided by *chroot*, *namespace* and *cgroups* **kernel features**. A process inside a container may see only a **subset** of the resources actually available on the host.
