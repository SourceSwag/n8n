#!/bin/bash

DOMAIN="n8n.leisuresafar.com"
EMAIL="Hedayatcore@gmail.com"
N8N_DIR="/home/ubuntu/n8n-server"

echo "📦 Updating system..."
sudo apt update -y && sudo apt install -y docker.io docker-compose ufw

echo "🔐 Enabling UFW firewall for security..."
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "📁 Creating n8n project folder..."
mkdir -p $N8N_DIR && cd $N8N_DIR

echo "📄 Writing docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3.8'

networks:
  n8n-network:
    external: false

services:
  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /etc/nginx/certs:/etc/nginx/certs:ro
      - /etc/nginx/vhost.d:/etc/nginx/vhost.d
      - /usr/share/nginx/html:/usr/share/nginx/html
      - /var/run/docker.sock:/tmp/docker.sock:ro
    networks:
      - n8n-network

  nginx-proxy-le:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: nginx-proxy-le
    environment:
      - NGINX_PROXY_CONTAINER=nginx-proxy
      - DEFAULT_EMAIL=$EMAIL
    volumes:
      - /etc/nginx/certs:/etc/nginx/certs
      - /etc/nginx/vhost.d:/etc/nginx/vhost.d
      - /usr/share/nginx/html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - nginx-proxy
    networks:
      - n8n-network

  n8n:
    image: n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_HOST=$DOMAIN
      - N8N_PORT=5678
      - WEBHOOK_URL=https://$DOMAIN/
      - VIRTUAL_HOST=$DOMAIN
      - VIRTUAL_PORT=5678
      - LETSENCRYPT_HOST=$DOMAIN
      - LETSENCRYPT_EMAIL=$EMAIL
    ports:
      - "5678"
    volumes:
      - .n8n:/home/node/.n8n
    networks:
      - n8n-network
EOF

echo "🚀 Starting containers..."
docker-compose up -d

echo "✅ Setup complete. Wait 1-2 minutes for SSL certificate generation."
echo "🔗 Then visit: https://$DOMAIN"
