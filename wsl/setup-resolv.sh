#!/bin/bash
set -x
sed -e "s/NAMESERVER/$1/" $(dirname -- "$0")/templates/resolv.conf | sudo tee /etc/resolv.conf
sudo chmod 644 /etc/resolv.conf
sudo systemctl enable systemd-resolved.service
