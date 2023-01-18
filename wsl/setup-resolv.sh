#!/bin/bash
set -x
sed -e "s/NAMESERVER/$1/" $(dirname -- "$0")/templates/resolved.conf | sudo tee /etc/systemd/resolved.conf
sudo chmod 644 /etc/systemd/resolved.conf
sudo systemctl enable systemd-resolved.service
sudo systemctl restart systemd-resolved.service
