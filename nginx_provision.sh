#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx

cat > /etc/nginx/sites-available/webapp <<'EOF'
upstream webapp {
    server app01:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://webapp;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp

nginx -t
systemctl enable nginx
systemctl restart nginx