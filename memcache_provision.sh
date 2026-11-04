#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y memcached

sed -i 's/^-l .*/-l 0.0.0.0/' /etc/memcached.conf

systemctl enable memcached
systemctl restart memcached