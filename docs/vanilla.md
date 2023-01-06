# Vanilla Kubernetes

> This page is under construction!

Things to be captured here:

1. The `kubelet` running on worker nodes expects `systemd-resolved` to be
   used, whereas Raspberry Pi OS uses `dhcpcd` instead. As with Rocky Linux
   users in this
   [kubeadm issue](https://github.com/kubernetes/kubeadm/issues/1124),
   Raspberry Pi OS required a symbolic link from `/etc/resolv.conf` to
   `/run/systemd/resolve`.
2. The CNI plugin seems to be a requirement. Nodes can be connected as
   workers, but some pods seem to require Calico or another CNI plugin to
   be running.
3. Calico needs to be created `kubectl -f create` not `apply`, because the
   annotations for one of its CRDs exceeeds the allowed bytes length. So
   unfortunately Kustomize can't be used.
