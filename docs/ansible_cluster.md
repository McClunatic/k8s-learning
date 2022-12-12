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

Our inventory looks like this:

``` title="ansible/inventory.yml"
--8<-- "../ansible/inventory.yml"
```

This inventory defines a `raspberrypis` group that contains to child groups:
a `canary` test group, and a `k8s` group. All hosts are accessed as user `pi`,
so we define `ansible_user` accordingly.
