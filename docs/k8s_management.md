# Managing a MicroK8s cluster

The
[Kubernetes documentation](https://kubernetes.io/docs/)
includes a great conceptual explanation of
[Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/):

> Kubernetes objects are persistent entities in the Kubernetes system.
> Kubernetes uses these entities to represent the state of your cluster.
> Specifically, they can describe:
>
> * What containerized applications are running (and on which nodes)
> * The resources available to those applications
> * The policies around how those applications behave, such as restart
>   policies, upgrades, and fault-tolerance
>
> A Kubernetes object is a "record of intent"--once you create the object, the
> Kubernetes system will constantly work to ensure that object exists. By
> creating an object, you're effectively telling the Kubernetes system what you
> want your cluster's workload to look like; this is your cluster's desired
> state.

We'll use a few different methods for working with Kubernetes Objects,
including:

* [MicroK8s addons](#microk8s-addons)
* [`kubectl`](#kubectl), the Kubernetes CLI
* [Kustomize](#kustomize), the Kubernetes customization tool
* [Juju](#juju), [Charmed Operator framework](https://juju.is/)

## MicroK8s addons

[MicroK8s addons](https://microk8s.io/docs/addons) are extra services that
can be enabled in MicroK8s, creating Objects, effectively functioning as a
[Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
We will use addons to enable:

* `dashboard`: The standard Kubernetes dashboard
* `dns`: CoreDNS
* `ingress`: A simple ingress controller for external access
* `metallb`: The [MetalLB](https://metallb.universe.tf/) LoadBalancer
* `storage`: A default storage class (replaced by `hostpath-storage` in
   latest versions of `microk8s`)

We can do that in one line (here providing `metallb` with an IP address
range to use for LoadBalancers) like this:

```shell
> microk8s enable dashboard dns ingress metallb:192.168.1.192/27 storage
```

## `kubectl`

[`kubectl`](https://kubernetes.io/docs/reference/kubectl/) is the CLI for
communicating with the Kubernetes control plane, and is able to perform
a large set of operations including `create`, `get`, `describe`, and `delete`.

We will use `kubectl` primarily for four operations:

1. To `patch` addons
2. To `create` secrets
3. To `create` tokens
4. To run `kustomize` (see [Kustomize](#kustomize) below)

An example of something to patch is the `ingress` controller, to enable
SSL passthrough for services that need to handle TLS themselves.

```shell
> k patch daemonset -n ingress nginx-ingress-microk8s-controller \
    --type=json \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'
```

Secrets can be created of different kinds, including `tls` and Opaque
(`generic`) secrets. For example, to create an Opaque secret containing
TLS certificate and key files from a `./certs/` directory, you can run:

```shell
> k create secret generic -n kube-system kubernetes-dashboard-certs --from-file=./certs
```

Tokens can be created to provide user credentials. For example, to generate
a token for `admin-user` you can run:

```shell
> k create token admin-user
```

> NOTE: In the above commands, `microk8s kubectl` has been aliased to `k`.

## Kustomize

[Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
is a standalone tool for customizing Kubernetes objects using
[kustomization files](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization).
Through those files, Kustomize allows you to:

* generate resources from other sources
* set cross-cutting fields for resources
* compose and customize collections of resources

The [Kustomize GitHub page](https://github.com/kubernetes-sigs/kustomize)
features a great explanation of usage. We will use `kustomize` to modify and
create resources on the cluster, including:

* Creating a LoadBalancer Service for the cluster
* Creating Ingress resources for the `dashboard` [addon](#microk8s-addons)
* Deploying Tekton Pipelines

A simple example of a Kustomization with a production
[overlay](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#overlay)
is the LoadBalancer Service. We define that Service with the following
resource definition, `k8s/nginx-ingress/base/ingress-service.yaml`:

```yaml
--8<-- "k8s/nginx-ingress/base/ingress-service.yaml"
```

We declare that resource in our kustomization file,
`k8s/nginx-ingress/base/kustomization.yaml`:

```yaml
--8<-- "k8s/nginx-ingress/base/kustomization.yaml"
```

Note both of these files live in a `base/` directory. In a neighboring
`overlays/prod` directory, we create our trivial production overlay,
`k8s/nginx-ingress/overlays/prod/kustomization.yaml`:

```yaml
--8<-- "k8s/nginx-ingress/overlays/prod/kustomization.yaml"
```

In this case, `prod` does not modify `base` at all, but it can and generally
will, for example applying labels to indicate the configuration and to
modify resources.

With the kustomizations defined, we can
[apply](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#how-to-apply-view-delete-objects-using-kustomize)
our `prod` overlay to the cluster as follows:

```shell
k apply -k k8s/nginx-ingress/overlays/prod
```

The implementations of all kustomizations can be viewed in the
[source code](https://github.com/McClunatic/k8s-learning/tree/main/k8s/).

## Juju

[Juju](https://juju.is/) is an open source framework that uses
[Charmed Operators](https://juju.is/docs/sdk/charmed-operators), or **Charms**,
to deploy cloud infrastructure and operations.

Our use case for using Juju is to install
[Kubeflow](https://www.kubeflow.org/), a machine learning toolkit for
Kubernetes. Specifically, we will use it to deploy
[Charmed Kubeflow](https://charmed-kubeflow.io/)'s `kubeflow-lite` bundle.

For installation steps, please refer to
[Charmed Kubeflow guidance](https://charmed-kubeflow.io/docs/install).
