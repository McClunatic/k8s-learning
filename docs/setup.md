# Setup

McCl8s is a 4-node K8s cluster deployed on four nodes. A Windows 11 machine
(with Ubuntu 22.04 via WSL 2) is used to run the control plane, and three
Raspberry Pi 3 machines are used as worker nodes.

In this section we'll cover setup, installation, and configuration work for:

1. [WSL-2](#wsl-2)
2. [Windows firewall](#windows-firewall)
3. [Podman](#podman)
4. [MicroK8s](#microk8s)
5. [Ansible](#ansible)

## WSL 2

> NOTE: As of November 15, 2022, WSL 2 has
> [reached 1.0.0](https://github.com/microsoft/WSL/discussions/9155),
> with Microsoft removing the preview label and making it
> [generally available in the Microsoft Store](https://devblogs.microsoft.com/commandline/the-windows-subsystem-for-linux-in-the-microsoft-store-is-now-generally-available-on-windows-10-and-11/).
> Instructions in this section assume the WSL 2 has been updated to 1.0.0.

### Switching networking to bridged mode

By default, WSL 2 runs in Network Access Translation (NAT) mode, meaning
it has a virtualized ethernet adapter with its own unique IP address.
This makes it challenging to access a WSL 2 distribution from another
local area network (LAN) machine. To enable access, there are two options:

1. To go through the same steps as one would for a regular virtual machine
   with an internal virtual network. This approach for
   [accessing a WSL 2 distribution from a LAN](https://learn.microsoft.com/en-us/windows/wsl/networking#accessing-a-wsl-2-distribution-from-your-local-area-network-lan)
   is documented by Microsoft.
2. To configure Windows, Hyper-V, and WSL 2 to support and run in bridged mode,
   allowing the WSL 2 distribution to acquire an IP address itself in the
   LAN.

#### Option 1: an example

IP addresses for the Ubuntu WSL 2 distribution are captured into the
`$hostnames` array. The primary IP address is then used as the connect address
for a port proxy started by `netsh`:

```ps1con
> $hostnames = @(& wsl -d Ubuntu hostname -I) -split ' '
> netsh interface portproxy add v4tov4 `
    listenport=25000 listenaddress=0.0.0.0 `
    connectport=25000 connectaddress=$hostnames[0]
```

#### Option 2: by reference

Setting up WSL 2 to run in bridged mode involves:

* Ensuring minimum version requirements for WSL 2 itself
* Setting up a bridged virtual switch in Hyper-V
* Reconfiguring WSL 2

This approach was discussed in a
[WSL GitHub feature request](https://github.com/microsoft/WSL/issues/4150#issuecomment-1303984769)
and more completely documented in this
[WSL 2 bridged mode networking guide](https://github.com/luxzg/WSL2-fixes/blob/master/networkingMode%3Dbridged.md).
Rather than repeating the documentation here, please follow this excellent
guide!

> Follow optional steps to enable `systemd`. It's a prerequisite for `snap`,
> which is used to install MicroK8s.

#### Why Option 2 is necessary

Option 1 is the simpler of the two, and for anonymous accessibility,
both options work, making Option 1 an easy choice.

However, for the K8s cluster use case, there are two problems:

1. Inbound connections from a port proxy will not come from the LAN
   IP address of the client, but the IP of the NAT router. MicroK8s will
   refuse to add nodes whose self-reported machine names do not match (per
   DNS lookup) the name associated with their IP.
2. Because *all* inbound connections will appear to WSL 2 as having come from
   the router IP, it is impossible to distinguish incoming MicroK8s join
   requests and therefore impossible to add multiple workers from the LAN.

Those complications disappear with a network bridge, making Option 2 the
necessary choice for a WSL 2 + Raspberry Pi MicroK8s cluster.

## Windows firewall

The Windows (WSL 2) machine will serve as the control plane for the cluster,
and must be reachable by worker nodes. To be reachable, the Windows Defender
firewall must be configured with new rules. ICMP access (used to ping) and
TCP access involve different rules. The following links provide guidance to
[create an inbound ICMP rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-icmp-rule)
and tolle TCP access to the machine (including for specific ports or port
ranges), follow the link to
[create an inbound port rule](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-firewall/create-an-inbound-port-rule).

## Podman

Podman is a daemonless container engine for developing and managing OCI
containers. [Installing Podman](https://podman.io/getting-started/installation)
is straightforward for most Linux OSes, with packages available in most
official repositories. It can be installed in Ubuntu as follows:

```shell
> # Ubuntu 20.10 and newer
> sudo apt-get -y update
> sudo apt-get -y install podman
```

## VS Code

As discussed in
[this GitHub  issue](https://github.com/microsoft/vscode-docker/issues/1590#issuecomment-769284759),
Podman can be used in place of Docker in the `vscode-docker` extension using
the following steps:

1. Run: `systemctl --user enable --now podman.socket`
2. Set VS Code option `docker.host` to `unix:///run/user/1000/podman/podman.sock`
   (this will persist once set)

> NOTE: [docker.host](https://github.com/microsoft/vscode-docker/issues/3539)
> was deprecated and removed as of Docker extension version 1.23. The new
> extension allows the user to specify environment variable/value pairs, but
> `DOCKER_HOST` does not work as of this writing. Follow
> [this issue](https://github.com/microsoft/vscode-docker/issues/3766) to
> track changes.

## MicroK8s

MicroK8s is a simple and fast way to get Kubernetes up and running, both for
development and production use. For the McCl8s cluster, getting MicroK8s
installed takes a few steps.

### Enabling `systemd`

If `systemd` was not enabled as part of configuring [WSL 2](#wsl-2), read more
about how to enable it in this
[Microsoft developer blog](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/).
It's a prerequisite for `snap`, which comes next.

### Installing `snapd`

Snaps are app packages for Linux that are cross-platform and dependency-free.
`snapd` can be installed on Ubuntu (if not already installed) by running:

```shell
> sudo apt update
> sudo apt install snapd
```

As discussed on
[Snap's installation page](https://snapcraft.io/docs/installing-snap-on-ubuntu),
you can optionally test `snap` after restarting by installing and running
a *hello-world* snap:

```shell
> sudo snap install hello-world
hello-world 6.4 from Canonical✓ installed
> hello-world
Hello World!
```

### Installing MicroK8s

[MicroK8s](https://microk8s.io/#install-microk8s) can be installed as a `snap`
package after [Installing `snapd`](#installing-snapd):

```shell
> sudo snap install microk8s --classic
```

Once MicroK8s is installed, you can check its status while it starts:

```shell
> microk8s status --wait-ready
```

The Kubernetes CLI, `kubectl`, is available as a `microk8s` subcommand:

```shell
> microk8s kubectl -h
```

For convenience, consider aliasing `microk8s kubectl`!

## Ansible

Per
[its own documentation](https://docs.ansible.com/ansible/latest/index.html),

> Ansible is an IT automation tool. It can configure systems, deploy software,
> and orchestrate more advanced IT tasks such as continuous deployments or
> zero downtime rolling updates.

To configure and deploy software to the cluster's Raspberry Pi worker nodes,
we'll use Ansible. It can be
[user installed](https://pip.pypa.io/en/latest/user_guide/#user-installs)
by running:

```shell
> sudo apt update && sudo apt install -y python3-pip
> pip3 install --user ansible
```
