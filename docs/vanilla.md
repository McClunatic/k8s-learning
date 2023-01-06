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
4. If running with swap disabled on WSL 2, beware the `swapoff -a` is a
   session-only change, not a permanent one, and that there is no
   `/etc/fstab` to modify. Instead, use the
   [`.wslconfig` swap setting](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configuration-setting-for-wslconfig)
   to disable swap for WSL 2 VMs.
