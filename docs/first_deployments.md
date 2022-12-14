# First deployments

With [setup](setup.md) complete, we can begin deployments.

## Enabling MicroK8s addons

To start, let's enable the standard Kubernetes dashboard:

```shell
> microk8s enable dashboard
```

Then, enable addons that will be required to install Kubeflow.
In the below example, we can also set an IP range for
`metallb` to use for external IPs:

```shell
> microk8s enable dns hostpath-storage ingress metallb:192.168.1.192/27
```

## Patching the ingress controller

The `ingress` addon runs `ingress-nginx`, a Kubernetes Ingress NGINX
controller. We need to enable
[SSL passthrough](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#ssl-passthrough)
to allow passthrough backends to Ingress objects. Do that by running the
following:

```shell
> k patch daemonset -n ingress nginx-ingress-microk8s-controller \
    --type=json \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'
```

## Adding an ingress Service

With `metallb` and `ingress` addons both active, we can follow
[MetalLB addon guidance](https://microk8s.io/docs/addon-metallb) to
set up an ingress Service. That can be done via `kubectl`, but we'll
use Kustomize. We define our ingress Service resource, a LoadBalancer,
in
[`k8s/nginx-ingress/base`](https://github.com/McClunatic/k8s-learning/tree/main/k8s/nginx-ingress):

```yaml
--8<-- "k8s/nginx-ingress/base/ingress-service.yaml"
```

Using our `prod` overlay, apply the service by running:

```shell
> k apply -k k8s/nginx-ingress/overlays/prod
```

## Exposing the Kubernetes Dashboard

With a LoadBalancer running, we can expose the Kubernetes Dashboard, making
it reachable via an external IP. As with the ingress Service, we have
Kustomize resources prepared for the dashboard. Apply those kustomizations
by running:

```shell
> k apply -k k8s/kubernetes-dashboard/overlays/prod
```

> Beyond the scope of the current documentation:
>
> * The Ansible dns.yml playbook is also configured to add the hostname of the
>   Ingress, > `kubernetes-dashboard.k8s.local`, to the DNS server.
> * The default certificates of the dashboard are self-signed and will not be
>   trusted by browsers. However, setting up a
>   [private CA with cfssl](https://www.ekervhen.xyz/posts/2021-02/private-ca-with-cfssl/)
>   and updating the `kubernetes-dashboard-certs` secret is an option to
>   serve a trusted Dashboard.

## Tekton

Per [Tekton documentation](https://tekton.dev/docs/),

> Tekton is a cloud-native solution for building CI/CD systems. It consists of
> Tekton Pipelines, which provides the building blocks, and of supporting
> components, such as Tekton CLI and Tekton Catalog, that make Tekton a
> complete ecosystem.

### Deploying Tekton resources

To deploy Tekton Pipelines and Tekton Triggers, apply the following
kustomizations:

```shell
> k apply -k k8s/tekton-pipelines/overlays/prod
> k apply -k k8s/tekton-triggers/overlays/prod
```

### Deploying the Dashboard

The kustomizations for Tekton Dashboard refer to a `tekton-pipelines`
namespace secret, `tekton-dashboard-tls`. We'll need to make that first.
Creating a TLS certificate/key pair is beyond the scope of the current
documentation, however you may follow guidance to create
[private CA with cfssl](https://www.ekervhen.xyz/posts/2021-02/private-ca-with-cfssl/)
here. The documentation example below assumes a `certificates/` directory with
certificate and key files for the dashboard.

To create the `tekton-dashboard-tls` certificate, refer to our certificate
and key by running:

```shell
> k create -n tekton-pipelines secret tls tekton-dashboard-tls \
    --cert=certificates/tekton-dashboard-fullchain.pem \
    --key=certificates/tekton-dashboard-key.pem
```

With the secret available, apply the dashboard kustomizations:

```shell
> k apply -k k8s/tekton-dashboard/overlays/prod
```
