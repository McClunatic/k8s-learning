# Learning Kubernetes

This repository will document resources and training to learn Kubernetes.

## Resources

* [Kubernetes Documentation](https://kubernetes.io/docs/home/)
* [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
* [Allow using podman instead of docker](https://github.com/microsoft/vscode-docker/issues/1590)
* [Kubernetes on Windows with WSL 2 and MicroK8s](https://youtu.be/DmfuJzX6vJQ)
* [Nuxt Installation](https://nuxt.com/docs/getting-started/installation)
* [Kubernetes Object Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/)
* [Getting started with Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html)
* [Accessing network applications with WSL](https://learn.microsoft.com/en-us/windows/wsl/networking)
* [Create a MicroK8s cluster](https://microk8s.io/docs/clustering)
* [Create an Inbound ICMP rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-icmp-rule)
* [Create an Inbound port rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-port-rule)
* [WSL2-fixes](https://github.com/luxzg/WSL2-fixes)
* [WSL 2 NIC Bridge mode](https://github.com/microsoft/WSL/issues/4150)

## Setup

### Setting up VS Code Docker extension to use Podman

*ℹ️ This section is optional for those installing Docker.*

Per [comment](https://github.com/microsoft/vscode-docker/issues/1590#issuecomment-769284759)
in `vscode-docker` extension GitHub issue 1590, Podman can be used in place
of Docker using the following steps:

1. Run: `systemctl --user enable --now podman.socket`
2. Set VS Code option `docker.host` to `unix:///run/user/1000/podman/podman.sock`
   (this will persist once set)

*ℹ️ The `1000` corresponds to your linux user `uid`. Run `id` to confirm your*
*`uid`.*

The guidance notes that

> Several commands will use `docker` by default but can be configured to use
> `podman` instead using
> [Command Customization](https://code.visualstudio.com/docs/containers/reference#_command-customization).
> Other than that, most explorer features should work fine. You can also set
> the `alias docker="podman"` in Linux as well.

An alternative to aliasing that may also solve the command default problem
is using a `~/.local/bin/docker` symbolic link to `podman`:

```bash
> ln -s $(which podman) ~/.local/bin/docker
```

### Installing Microk8s

Follow linked guidance to run
[Kubernetes on Windows with WSL 2 and Microk8s](https://youtu.be/DmfuJzX6vJQ).
Two things to note while reading the referenced blog detailing setup:

1. As of September 2022,
   [systemd is now available in WSL](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/)!
2. The multi-node setup is nice, but not strictly necessary for a learning
   environment.

### Creating a Nuxt app

The `nuxt-app/` directory in this repository was created following
[Nuxt Installation](https://nuxt.com/docs/getting-started/installation)
guidance. To run the "Welcome to Nuxt" app, with Node.js installed, run

```shell
> npm run dev -- -o
```

### Building the Nuxt app container

The `Dockerfile` defines a simple recipe for containerizing the "Welcome to
Nuxt" app. To build the container, run:

```shell
> docker build -t <username>/nuxt-app .
```

### Publishing to Docker Hub

Kubernetes expects images in its `.yaml` file object specs
(e.g., one specifying a **Deployment**) to be *hosted*. By default, it will
attempt to fetch image names from Docker Hub. To make sure the `nuxt-app`
image can be fetched as part of creating a Deployment, log in to Docker
Hub and push the image as follows:

```shell
> docker login -u <username> -p <password>
```

> If you don't have a Docker Hub account, create one to complete this!

```shell
> docker push <username>/nuxt-app
```

### Creating a Nuxt app deployment

The `nuxt-app.deployment.yaml` defines the defines the Kubernetes Deployment
for the "Welcome to Nuxt" app, using the published `nuxt-app` container
image. To create the Deployment, there are several different options
discussed in detail in
[Kubernetes Object Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/).
The following example takes a declarative approach:

```shell
kubectl apply -f nuxt-app.deployment.yaml
```

### Setting up Ansible

From Ansible's documentation:

> Ansible is an IT automation tool. It can configure systems, deploy software,
> and orchestrate more advanced IT tasks such as continuous deployments or zero
> downtime rolling updates.
>
> Ansible’s main goals are simplicity and ease-of-use. It also has a strong
> focus on security and reliability, featuring a minimum of moving parts, usage
> of OpenSSH for transport (with other transports and pull modes as
> alternatives), and a language that is designed around auditability by
> humans–even those not familiar with the program.

This section is optional, meant to support setup, configuration, and
maintenance of nodes in a Kubernetes cluster. To read more, follow the link to
[get started with Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html).

#### Installing Ansible

Installing Ansible (on what will be the *control node*) requires a Python 3.8
or higher on the system, with pip installed as well. To ensure pip is installed
on Ubuntu 22.04 LTS, for example, run:

```shell
> sudo apt install python3-pip python3-pip-whl
```

With pip installed, install Ansible for the current user as follows:

```shell
> python3 -m pip install --user ansible
```

#### Creating an inventory

Create an inventory file by adding the IP addresses or fully qualified domain
names of the remote nodes to manage (to make *managed nodes*). For example,
with a cluster of 4 Raspberry Pi systems with a default user `pi`, an
inventory might look like this:

```ini
[raspberrypis]
192.168.1.100
192.168.1.101
192.168.1.102
192.168.1.103

[raspberrypis:vars]
ansible_user=pi
```

> The `ansible_user` ensures connections are established using the `pi` user
> if the user on the control node is another username.

The default location for the inventory file is `/etc/ansible/hosts`.
One can use another location and specify that file when running ansible
commands (here, with `-i ~/.ansible/etc/hosts`):

```shell
> ansible -i ~/.ansible/etc/hosts raspberrypis -m ping
192.168.1.102 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
192.168.1.101 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
192.168.1.100 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
192.168.1.103 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

A richer format for an inventory file is YAML. Here, we modify the previous
example to provide named hosts for each IP:

```yaml
raspberrypis:
  hosts:
    raspberrypi-0:
      ansible_host: 192.168.1.100
    raspberrypi-1:
      ansible_host: 192.168.1.101
    raspberrypi-2:
      ansible_host: 192.168.1.102
    raspberrypi-3:
      ansible_host: 192.168.1.103
  vars:
    ansible_user: pi
```

### Accessing WSL 2 from a local area network (LAN)

To [access a WSL 2 distribution from a LAN](https://learn.microsoft.com/en-us/windows/wsl/networking#accessing-a-wsl-2-distribution-from-your-local-area-network-lan),
the steps are the same as for a regular virtual machine. That is, port
forwarding (e.g., via a port proxy) is required between the Windows environment
and the WSL 2 VM.

In the following example, IP addresses for the Ubuntu WSL 2 distribution are
captured into the `$hostnames` array. The primary IP address is then used as
the connect address for a port proxy started by `netsh`:

```ps1con
> $hostnames = @(& wsl -d Ubuntu hostname -I) -split ' '
> netsh interface portproxy add v4tov4 `
    listenport=25000 listenaddress=0.0.0.0 `
    connectport=25000 connectaddress=$hostnames[0]
```

This step is necessary to enable connecting microk8s worker instances to a main
instance (running the control plane) running in WSL 2.

### Creating an Inbound Firewall Rules

To make the Windows machine reachable, the Windows Defender firewall needs to
be configured with new rules. To be able to ping a machine, follow the link
to
[create an inbound ICMP rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-icmp-rule).
To enable TCP access to the machine (including for specific ports or port
ranges), follow the link to
[create an inbound port rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-port-rule).

### Creating a MicroK8s cluster

To add nodes to the master of the cluster, run `microk8s add-node`. An
example execution will look as follows:

```shell
> microk8s add-node
From the node you wish to join to this cluster, run the following:
microk8s join 172.18.176.244:25000/897fea98332cec0bb9629751b236d055/a22af98532f8

Use the '--worker' flag to join a node as a worker not running the control plane, eg:
microk8s join 172.18.176.244:25000/897fea98332cec0bb9629751b236d055/a22af98532f8 --worker

If the node you are adding is not reachable through the default interface you can use one of the following:
microk8s join 172.18.176.244:25000/897fea98332cec0bb9629751b236d055/a22af98532f8
```

The output instructions to be executed on the MicroK8s instances that should
join the cluster (i.e. not the node `add-node` was run from.)

> NOTE: If running from WSL 2, the IP address used (in the example above,
> 172.18.176.244) is one associated with a virtualized ethernet adapter, not
> visible on the LAN. Follow instructions above to set up a port proxy and
> modify the `join` commands as needed.
