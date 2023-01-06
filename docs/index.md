# McCl8s

McCl8s is a tongue-in-cheek portmanteau of my last name and
[Kubernetes](https://kubernetes.io), or K8s. It is **not** a custom
implementation of K8s, but a name for the collection of applications
and resources deployed using [MicroK8s](https://microk8s.io) as a
platform for experimentation and learning.

## Sections

* [Learning topics](topics.md): Outlines the tools and concepts
  targeted for learning as part of building McCl8s.
* [Setup](setup.md): Covers configuration and installation of
  foundation hardware and software used to build McCl8s.
* [Cluster setup with Ansible](ansible_cluster.md): Covers automation
  of configuration and software installs for Raspberry Pi cluster
  workers using Ansible.
* [Managing a K8s cluster](k8s_management.md): Provides an overview
  of options for managing resources in a Kubernetes cluster.
* [First deployments](first_deployments.md): Serves as a guide for
  creating and modifying our first Kubernetes resources.
* [Kubeflow](kubeflow.md): Introduces Kubeflow and provides guidance
  for deployment.
* [Vanilla Kubernetes](vanilla.md): Discusses the work involved to
  start up a Kubernetes cluster using `kubeadm` rather than
  Microk8s.
