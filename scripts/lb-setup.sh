#!/bin/bash
echo "--- Provisioning Load Balancer (lb01) ---"

##############################################################
# 1. Install Nginx and stream module
##############################################################
echo "--> Installing Nginx and stream module..." 
sudo yum install -y nginx nginx-mod-stream > /dev/null

###############################################################
# 		2. Create HTTPS Certificate and Set Permissions
###############################################################
sudo mkdir -p /etc/ssl/private
sudo mkdir -p /etc/ssl/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/CN=applicationx.domain.com"
sudo chown root:nginx /etc/ssl/private/nginx-selfsigned.key
sudo chmod 640 /etc/ssl/private/nginx-selfsigned.key
##############################################################
# 3. Create Nginx configuration for SSL Passthrough 
# Uncomment this block to enable Layer 4 Load Balancing.
# Make sure to comment out the Layer 7 load balancer configuration before doing so.
##############################################################
echo "--> Creating Nginx configuration for SSL Passthrough..."
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EMD'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

stream {
    upstream gunicorn_servers {
        server 192.168.100.11:5000;
        server 192.168.100.12:5000;
        server 192.168.100.13:5000;
    }
    server {
        listen 443;
        proxy_pass gunicorn_servers;
    }
}

http {
    server {
        listen 80;
        server_name applicationx.domain.com;
        return 301 https://$host$request_uri;
    }
}
EMD

# Verify Nginx config
sudo nginx -t
##############################################################
# 4. Create Nginx configuration for Layer 7 loadblancer
# Uncomment this block to enable Layer 7 Load Balancing.
# Make sure to comment out the Layer 4 load balancer configuration before doing so.
##############################################################
# sudo tee /etc/nginx/nginx.conf > /dev/null << 'EMD'
# user nginx;
# worker_processes auto;
# error_log /var/log/nginx/error.log notice;
# pid /run/nginx.pid;
# include /usr/share/nginx/modules/*.conf;

# events {
#     worker_connections 1024;
# }

# # =====================================================================
# # Layer 7 Load Balancing (SSL Termination) Configuration
# # =====================================================================
# http {
#     include       /etc/nginx/mime.types;
#     default_type  application/octet-stream;

#     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                       '$status $body_bytes_sent "$http_referer" '
#                       '"$http_user_agent" "$http_x_forwarded_for"';

#     access_log  /var/log/nginx/access.log  main;

#     sendfile        on;
#     keepalive_timeout  65;

#     # Define the upstream group of web servers
#     upstream backend_servers {
#         #round_robin;
#         least_conn;
#         # ip_hash;

#         server 192.168.100.11:5000 max_fails=3 fail_timeout=10s ;
#         server 192.168.100.13:5000 max_fails=3 fail_timeout=10s ;
#         server 192.168.100.12:5000 max_fails=3 fail_timeout=10s weight=5;
#     }

#     server {
#         listen 80;
#         server_name applicationx.domain.com;
#         return 301 https://$host$request_uri;
#     }

#     server {
#         listen 443 ssl;
#         server_name applicationx.domain.com;

#         ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
#         ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

#         ssl_protocols TLSv1.2 TLSv1.3;
#         ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256';
#         ssl_prefer_server_ciphers on;

#         # --- Gzip Compression ---
#         gzip on;
#         gzip_vary on;
#         gzip_proxied any;
#         gzip_comp_level 6;
#         gzip_buffers 16 8k;
#         gzip_http_version 1.1;
#         gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss text/javascript image/svg+xml;

#         location / {
#             proxy_pass https://backend_servers;
#             proxy_set_header Host $host;
#             proxy_set_header X-Real-IP $remote_addr;
#             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#             proxy_set_header X-Forwarded-Proto $scheme;

#             proxy_connect_timeout 60s;
#             proxy_send_timeout 60s;
#             proxy_read_timeout 60s;
#             proxy_ssl_verify off;

#             # CORS headers
#              add_header 'Access-Control-Allow-Origin' '*';
#              add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
#              add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
#              add_header 'Access-Control-Allow-Credentials' 'true';
#              add_header 'Access-Control-Max-Age' 1728000;
#              if ($request_method = 'OPTIONS') {
#                  return 204;
#              }
#         }
#     }
# }
# EMD
# sudo nginx -t
##############################################################
# 5. Start and Enable Nginx
##############################################################
echo "--> Starting and enabling Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

##############################################################
# 6. Configure Firewall
##############################################################
echo "--> Configuring Firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --zone=public --add-service=http > /dev/null
sudo firewall-cmd --permanent --zone=public --add-service=https > /dev/null
sudo firewall-cmd --reload

##############################################################
# 7. Verify that Nginx is running and listening on port 443
##############################################################
echo "--> Verifying Nginx port listening:"
if sudo ss -tuln | grep -q ':443'; then
  echo " Nginx is listening on port 443"
else
  echo " Nginx is NOT listening on port 443"
fi

echo "--- Load Balancer (lb01) Provisioning Complete ---"
