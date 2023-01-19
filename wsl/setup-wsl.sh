#!/bin/bash
set -x
sed -e "s/HOSTNAME/$1/" $(dirname -- "$0")/templates/wsl.conf | sudo tee /etc/wsl.conf
sudo chmod 644 /etc/wsl.conf 
sed -e "s/IP_ADDRESS/$2\/24/" $(dirname -- "$0")/templates/netplan-config.yaml | sudo tee /etc/netplan/10-custom-config.yaml
sudo chmod 644 /etc/netplan/10-custom-config.yaml
