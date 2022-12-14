# Cluster setup with Ansible

For this setup, four Raspberry Pi nodes are available on the network. We
will configure one as both a network DNS server and as a test node for
applying
[Ansible playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html).
We will configure the remaining three nodes to join our MicroK8s cluster
as workers nodes.

## Getting started

[Ansible documentation](https://docs.ansible.com/ansible/latest/getting_started/index.html)
introduces three main components of an Ansible environment:

1. A **control node**, where Ansible is installed.
2. **Managed nodes**, remote hosts that Ansible controls.
3. **Inventory**, a list of logically organized managed nodes.

In this parlance, the WSL 2 machine will behave as the control node, and the
four Raspberry Pi machines as managed nodes.

## Creating the inventory

Ansible inventories defines the managed nodes to automate, with groups so you
can run automation tasks on multiple hosts at the same time. With an inventory
defined, you can use patterns to select the hosts or groups for Ansible to run
against.

For example, with a cluster of 4 Raspberry Pi systems with a default user `pi`,
an inventory might look like this:

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

The inventory we'll use throughout this documentation looks like:

```yaml
--8<-- "ansible/inventory.yml"
```

This inventory defines a `raspberrypis` group that contains to child groups:
a `canary` test group, and a `k8s` group. All hosts are accessed as user `pi`,
so we define `ansible_user` accordingly.

## Creating roles

Echoing the
[Roles documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
for Ansible:

> Roles let you automatically load related vars, files, tasks, handlers, and
> other Ansible artifacts based on a known file structure. After you group your
> content in roles, you can easily reuse them and share them with other users.

There are three roles needed to configure the Pis:

1. A `common` role, for tasks shared by all nodes. Every node, for example,
   should be updated and upgraded. And every node should have `snap` and
   `microk8s` installed.
2. A `dnsservers` role, unique to the test node that we will use as our
   local network DNS server.
3. A `workers` role, unique to the `k8s` group, the nodes that will join
   the `microk8s` cluster as workers.

> NOTE: The WSL 2 machine is behaving as both the MicroK8s cluster control
> plane and the Ansible control node.

The details of the `common` and `dnsservers` roles are not covered here, but
the implementations for each can be viewed in the
[source code](https://github.com/McClunatic/k8s-learning/tree/main/ansible/roles).
The `tasks/main.yml` for the `workers` is shown below:

```yaml
--8<-- ansible/roles/workers/tasks/main.yml
```

Worth highlighting here are the presence of *variables* that Ansible can
populate either from variables files or the command line at runtime. We will
make use of the `microk8s_instance` variable when running an associated
[playbook](#setting-up-playbooks).

## Setting up playbooks

With our three [roles](#creating-roles) defined, there are three associated
playbooks to create:

1. `site.yml` to update all nodes and install `microk8s`,
2. `dns.yml` to create a DNS server (and to update all other nodes to use
   that server), and
3. `k8sworkers.yml` to join `k8s` nodes to the MicroK8s cluster.

In each, we can refer to associated roles to run their tasks. For example,
the `k8sworkers.yml` playbook looks like this:

```yaml
--8<-- "ansible/k8sworkers.yml"
```

The remaining two playbooks
[source code](https://github.com/McClunatic/k8s-learning/tree/main/ansible/roles).
In our `k8sworkers.yml` playbook, we can see by default that `k8s` hosts are
targeted from our inventory, but that `variable_host` can be used to
override that setting at runtime. This is useful for testing configuration
changes on our `canary` host before rolling out to `k8s` hosts.

## Running playbooks

Playbooks are run using the `ansible-playbook` CLI:

```shell
> ansible-playbook -h
```

For our playbooks, we'll run them with one other argument to indicate the
inventory file to use. For example, running the `site.yml` playbook
from our `ansible/` repository directory looks like this:

```shell
> cd ansible/
> ansible-playbook -i inventory.yml site.yml
```

The more interesting playbook is our `k8sworkers.yml` playbook. To
[add nodes to MicroK8s](https://microk8s.io/docs/clustering), the
follow command must first be run from cluster master node:

```shell
> microk8s add-node
```

It outputs instructions like the following, which include URLs with unique
tokens and associated expiry times:

```shell
From the node you wish to join to this cluster, run the following:
microk8s join 192.168.1.230:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05

Use the '--worker' flag to join a node as a worker not running the control plane, eg:
microk8s join 192.168.1.230:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05 --worker

If the node you are adding is not reachable through the default interface you can use one of the following:
microk8s join 192.168.1.230:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05
microk8s join 10.23.209.1:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05
microk8s join 172.17.0.1:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05
```

To run our playbook, we first need to obtain a join URL from the MicroK8s
cluster master, and then provide that URL to the task in `workers` role,
awaiting it via the variable `microk8s_instance`
(see [Creating roles](#creating-roles)).

Running that playbook might look like this:

```shell
> ansible-playbook -i inventory.yml k8sworkers.yml \
    --extra-vars "microk8s_instance=192.168.1.230:25000/92b2db237428470dc4fcfc4ebbd9dc81/2c0cb3284b05"
```

Here's a handy one-liner to both extend the token expiry time and capture the
URL:

```shell
> ansible-playbook -i inventory.yml k8sworkers.yml \
    --extra-vars "microk8s_instance=$(microk8s add-node --token-ttl 3600 | grep microk8s | head -1 | cut -d' ' -f3)"
```
