# Hands-on lab scripts

The scripts you find here work only on Ubuntu based machines.

At least the Ubuntu 22.04 version is recommended because cgroup v2 is enabled by default and it does not require any further configuration.

When `systemd` acts as the init system for a linux distribution, it is recommended to configure systemd as the cgroup driver for both the kubelet and the container runtime.

The systemd cgroup driver is recommended if you use cgroup v2.