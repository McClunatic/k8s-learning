#!/bin/bash
# Usage: setup-kubernetes.sh ["control-plane"|"worker"] POD_CIDR
# Examples:
#   setup-kubernetes.sh control-plane 10.90.0.0/16
#   setup-kubernetes.sh worker

set -x

sysctl_ip_forward() {
    sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
    sudo sysctl -p
}

install_miniconda() {
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b
    rm Miniconda3-latest-Linux-x86_64.sh
}

install_containerd() {
    wget https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
    sudo tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz 
    rm containerd-1.6.14-linux-amd64.tar.gz 
    sudo mkdir -p /usr/local/lib/systemd/system
    sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /usr/local/lib/systemd/system
    sudo systemctl daemon-reload
    sudo systemctl enable --now containerd
}

install_runc() {
    wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
    sudo install -m 755 runc.amd64 /usr/local/sbin/runc
    rm runc.amd64
}

install_cni_plugins() {
    wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
    sudo mkdir -p /opt/cni/bin
    sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
    rm cni-plugins-linux-amd64-v1.1.1.tgz
    containerd config default > config.toml
    patch < $(dirname -- "$0")/patches/config.toml.$1.patch
    sudo mkdir -p /etc/containerd
    sudo cp config.toml /etc/containerd
    rm config.toml
    sudo systemctl restart containerd
}

install_cuda() {
    sudo apt update
    sudo apt upgrade -y

    wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin
    sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600
    [[ -e cuda-repo-wsl-ubuntu-12-0-local_12.0.0-1_amd64.deb ]] || wget \
        https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda-repo-wsl-ubuntu-12-0-local_12.0.0-1_amd64.deb
    sudo dpkg -i cuda-repo-wsl-ubuntu-12-0-local_12.0.0-1_amd64.deb
    sudo cp /var/cuda-repo-wsl-ubuntu-12-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda
}

install_nvidia_container_toolkit() {
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
}

install_kube_binaries() {
    sudo apt update
    sudo apt install -y ethtool socat conntrack
    sudo apt install -y apt-transport-https ca-certificates curl
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}

kubeadm_init() {
    sudo kubeadm init --control-plane-endpoint=$1 --pod-network-cidr=$2
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

if [[ "$1" == "control-plane" ]]
then
    mode=nocuda
elif [[ "$1" == "worker" ]]
then
    mode=cuda
else
    echo "First argument must be 'control-plane' or 'worker'"
    exit 1
fi

sysctl_ip_forward
install_miniconda
install_containerd
install_runc
install_cni_plugins $mode
if [[ "$mode" == "cuda" ]]
then
    install_cuda
    install_nvidia_container_toolkit
fi
install_kube_binaries
[[ "$1" == "control-plane" ]] && kubeadm_init $(hostname) $2
