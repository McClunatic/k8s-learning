#!/bin/bash
set -x
sed -e "s/HOSTNAME/$1/" $(dirname -- "$0")/templates/wsl.conf | sudo tee /etc/wsl.conf
sudo chmod 644 /etc/wsl.conf 
sed -e "s/IP_ADDRESS/$2/" $(dirname -- "$0")/templates/wsl-e.network | sudo tee /lib/systemd/network/wsl-e.network
sudo chmod 644 /lib/systemd/network/wsl-e.network 
sudo systemctl enable systemd-networkd
