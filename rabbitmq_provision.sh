#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Load configuration
CONFIG_FILE="/vagrant/config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config.env not found!"
    exit 1
fi

set -a
source "$CONFIG_FILE"
set +a

# Validate required variables
: "${RMQ_USER:?RMQ_USER is missing}"
: "${RMQ_PASS:?RMQ_PASS is missing}"

# Install RabbitMQ
apt-get update -y
apt-get install -y rabbitmq-server

systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

# Create or update RabbitMQ user
if rabbitmqctl list_users | awk 'NR > 1 {print $1}' | grep -Fxq "$RMQ_USER"; then
    rabbitmqctl change_password "$RMQ_USER" "$RMQ_PASS"
else
    rabbitmqctl add_user "$RMQ_USER" "$RMQ_PASS"
fi

# Configure permissions
rabbitmqctl set_user_tags "$RMQ_USER" administrator
rabbitmqctl set_permissions -p / "$RMQ_USER" ".*" ".*" ".*"

echo "RabbitMQ provisioning completed successfully."