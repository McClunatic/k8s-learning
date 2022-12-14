# Kubeflow

Per the [Kubeflow documentation](https://www.kubeflow.org/docs/),

> The Kubeflow project is dedicated to making deployments of machine learning
> (ML) workflows on Kubernetes simple, portable and scalable. Our goal is not
> to recreate other services, but to provide a straightforward way to deploy
> best-of-breed open-source systems for ML to diverse infrastructures. Anywhere
> you are running Kubernetes, you should be able to run Kubeflow.

## Installation

> NOTE: As of this writing, the installation guidance only works for a
> single-node MicroK8s cluster. Do not add the Pi nodes as workers. The
> first apparent issue: the `hostpath-storage` addon creates a PersistentVolume
> on the master node (`zephyrus`) but the PersistentVolumeClaim (PVC) created
> by Juju as part of installing Kubeflow maps to a Pi node, meaning the
> PVC will pend indefinitely.
>
> It is also possible that the RAM requirements of Kubeflow would exceed
> those available on the Pi nodes.

As discussed in [Managing a K8s cluster](k8s_management.md#juju), we will
install
[Charmed Kubeflow using `juju`](https://charmed-kubeflow.io/docs/quickstart).
With `microk8s` and `juju` already installed, the steps are:

1. Bootstrap Juju to MicroK8s, deploying a controller to MicroK8s' Kubernetes:

   ```shell
   > juju bootstrap microk8s
   ```

   The contoller is Juju's agent, running on Kubernetes, which can be used to
   deploy and control the components of Kubeflow. The controller works with
   `models`, which map to namespaces in Kubernetes.

2. Add a model! For Kubeflow, the model **must** be named `kubeflow`:

   ```shell
   > juju add-model kubeflow
   ```

3. Deploy a Kubeflow bundle. We will deploy a lighter option, `kubeflow-lite`:

   ```shell
   > juju deploy kubeflow-lite --trust
   ```

4. Wait for and monitor the deployment process. It can take tens of minutes:

   ```shell
   > watch -c juju status --color
   ```

## Dashboard access

With Kubeflow deployed, the next step is dashboard access. The dashboard
is accessed through a central `istio-ingressgateway`. We first need to
find the external IP assigned to its LoadBalancer. To do that, run the
following:

```shell
> k -n kubeflow get svc istio-ingressgateway-workload \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

> NOTE: Here, `k` is an alias for `microk8s kubectl`.

For this documentation, we will presume the IP is `192.168.1.193`.
Next, set up [Dex](https://dexidp.io/) authentication credentials:

```shell
> juju config dex-auth static-username=admin
> juju config dex-auth static-password=password
```

> NOTE: These are trivial credentials, feel free to choose a more secure
> password.

Finally, access the dashboard with the IP captured above via browser, and
log in using your chosen credentials.

> NOTE: As of this writing, only *insecure* HTTP access is working. Secure
> HTTP access is being refused. Documentation will be updated when this is
> resolved.
