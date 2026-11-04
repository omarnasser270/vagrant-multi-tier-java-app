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
: "${DB_NAME:?DB_NAME is missing}"
: "${DB_USER:?DB_USER is missing}"
: "${DB_PASS:?DB_PASS is missing}"

# Install MariaDB
apt-get update -y
apt-get install -y mariadb-server

# Allow remote connections
grep -rl "^bind-address" /etc/mysql/ | \
    xargs -r sed -i 's/^bind-address.*/bind-address = 0.0.0.0/'

systemctl enable mariadb
systemctl restart mariadb

# Configure database and user
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"

mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"

mysql -e "ALTER USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';"

mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"

mysql -e "FLUSH PRIVILEGES;"

# Import database backup if available
if [[ -f /vagrant/app_src/db_backup.sql ]]; then
    mysql "${DB_NAME}" < /vagrant/app_src/db_backup.sql
fi

echo "MariaDB provisioning completed successfully."