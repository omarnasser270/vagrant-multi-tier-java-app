

#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# ==========================================
# Configuration
# ==========================================

TOMCAT_VER="10.1.26"

REPO_URL="https://github.com/hkhcoder/vprofile-project.git"
REPO_BRANCH="local"

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
: "${RMQ_USER:?RMQ_USER is missing}"
: "${RMQ_PASS:?RMQ_PASS is missing}"

MEMCACHED_HOST="mc01"
RABBITMQ_HOST="rmq01"
DB_HOST="db01"

TOMCAT_HOME="/usr/local/tomcat"
JAVA_PATH="/usr/lib/jvm/java-17-openjdk-amd64"

# ==========================================
# Validate Configuration
# ==========================================

if [[ "$REPO_URL" == "PUT_APP_REPO_URL_HERE" ]]; then
    echo "ERROR: Set REPO_URL first."
    exit 1
fi

echo "=========================================="
echo " Starting Tomcat Provisioning"
echo " Tomcat Version: $TOMCAT_VER"
echo "=========================================="

# ==========================================
# Install Dependencies
# ==========================================

apt-get update -y

apt-get install -y \
    openjdk-17-jdk \
    maven \
    git \
    wget \
    mariadb-client

export JAVA_HOME="$JAVA_PATH"
export PATH="$JAVA_HOME/bin:$PATH"

# ==========================================
# Create Tomcat User
# ==========================================

if ! id tomcat &>/dev/null; then
    useradd -m -d "$TOMCAT_HOME" -s /usr/sbin/nologin tomcat
fi

# ==========================================
# Stop Existing Tomcat
# ==========================================

systemctl stop tomcat 2>/dev/null || true

# ==========================================
# Install Tomcat 10.1.26
# ==========================================

echo "Installing Tomcat $TOMCAT_VER..."

wget -q \
    "https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz" \
    -O /tmp/tomcat.tar.gz

# Remove old installation
rm -rf "$TOMCAT_HOME"

mkdir -p "$TOMCAT_HOME"

# Extract new installation
tar -xzf /tmp/tomcat.tar.gz \
    --strip-components=1 \
    -C "$TOMCAT_HOME"

rm -f /tmp/tomcat.tar.gz

chown -R tomcat:tomcat "$TOMCAT_HOME"

chmod +x "$TOMCAT_HOME"/bin/*.sh

echo "Tomcat installation completed."

# ==========================================
# Configure Systemd Service
# ==========================================

cat > /etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
Type=simple
User=tomcat
Group=tomcat

Environment=JAVA_HOME=${JAVA_PATH}
Environment=JRE_HOME=${JAVA_PATH}
Environment=CATALINA_HOME=${TOMCAT_HOME}
Environment=CATALINA_BASE=${TOMCAT_HOME}

ExecStart=${TOMCAT_HOME}/bin/catalina.sh run
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tomcat

# ==========================================
# Clone Application Repository
# ==========================================

echo "Cloning application repository..."

rm -rf /tmp/app

git clone -b "$REPO_BRANCH" "$REPO_URL" /tmp/app

cd /tmp/app

# ==========================================
# Configure Application Properties
# ==========================================

PROPS=$(find . -name application.properties \
    -path "*src/main/resources*" -print -quit)

if [[ -z "$PROPS" ]]; then
    echo "ERROR: application.properties not found."
    exit 1
fi

echo "Configuring application properties..."

sed -i "s#^jdbc.url=.*#jdbc.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME}?useUnicode=true\\&characterEncoding=UTF-8\\&zeroDateTimeBehavior=convertToNull#" "$PROPS"

sed -i "s#^jdbc.username=.*#jdbc.username=${DB_USER}#" "$PROPS"

sed -i "s#^jdbc.password=.*#jdbc.password=${DB_PASS}#" "$PROPS"

sed -i "s#^memcached.active.host=.*#memcached.active.host=${MEMCACHED_HOST}#" "$PROPS"

sed -i "s#^rabbitmq.address=.*#rabbitmq.address=${RABBITMQ_HOST}#" "$PROPS"

sed -i "s#^rabbitmq.username=.*#rabbitmq.username=${RMQ_USER}#" "$PROPS"

sed -i "s#^rabbitmq.password=.*#rabbitmq.password=${RMQ_PASS}#" "$PROPS"

# ==========================================
# Import Database
# ==========================================

SQL=$(find . -name db_backup.sql -print -quit || true)

if [[ -n "$SQL" ]]; then
    echo "Importing database..."

    mysql \
        -h "$DB_HOST" \
        -u "$DB_USER" \
        -p"$DB_PASS" \
        "$DB_NAME" < "$SQL"

    echo "Database import completed."
else
    echo "WARNING: db_backup.sql not found."
fi

# ==========================================
# Build Application
# ==========================================

echo "Building application with Maven..."

mvn -q clean package -DskipTests

WAR_FILE=$(find target -maxdepth 1 -name "*.war" -print -quit)

if [[ -z "$WAR_FILE" ]]; then
    echo "ERROR: WAR file was not generated."
    exit 1
fi

echo "WAR generated: $WAR_FILE"

# ==========================================
# Deploy Application
# ==========================================

echo "Deploying application..."

systemctl stop tomcat 2>/dev/null || true

rm -rf "$TOMCAT_HOME"/webapps/ROOT
rm -f "$TOMCAT_HOME"/webapps/ROOT.war

cp "$WAR_FILE" "$TOMCAT_HOME"/webapps/ROOT.war

chown -R tomcat:tomcat "$TOMCAT_HOME"

# ==========================================
# Start Tomcat
# ==========================================

systemctl daemon-reload
systemctl restart tomcat

echo "Waiting for Tomcat..."

sleep 5

if ! systemctl is-active --quiet tomcat; then
    echo "ERROR: Tomcat failed to start."
    journalctl -u tomcat --no-pager -n 50
    exit 1
fi

# ==========================================
# Verify Installation
# ==========================================

echo "=========================================="
echo " Tomcat Version:"
"$TOMCAT_HOME/bin/version.sh" | grep "Server number"

echo " Tomcat Service:"
systemctl is-active tomcat

echo "=========================================="
echo " Tomcat Provisioning Completed!"
echo "=========================================="
