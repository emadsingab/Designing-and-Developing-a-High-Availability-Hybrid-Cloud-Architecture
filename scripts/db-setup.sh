#!/bin/bash

echo "--- Provisioning Database Server ($(hostname)) ---"

# ================================
# 1. Update packages & install tools
# ================================
echo "--> Updating packages and installing prerequisites..."
sudo apt-get update -y > /dev/null
sudo apt-get install -y curl gnupg lsb-release software-properties-common > /dev/null

# ================================
# 2. Setup MariaDB Repository
# ================================
echo "--> Setting up MariaDB repository..."
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash > /dev/null

# Install MariaDB
echo "--> Installing MariaDB server..."
sudo apt-get update -y > /dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server > /dev/null

# Enable & start service
sudo systemctl enable --now mariadb
ت
# ================================
# 3. Configure MariaDB for remote access
# ================================
echo "--> Configuring MariaDB for remote access..."

sudo sed -i 's/^bind-address.*/bind-address = 192.168.100.10/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

# ================================
# 4. Create DB + User + Table
# ================================
echo "--> Creating database and user..."

sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS company_db;
CREATE USER IF NOT EXISTS 'app_user'@'192.168.100.%' IDENTIFIED BY 'cairo123';
GRANT ALL PRIVILEGES ON company_db.* TO 'app_user'@'192.168.100.%';
FLUSH PRIVILEGES;
EOF

echo "--> Creating table schema..."
sudo mysql -u root company_db <<EOF
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    position VARCHAR(50),
    salary FLOAT
);
EOF

# ================================
# 5. Verify MySQL port
# ================================
echo "--> Verifying MySQL port listening..."
sudo ss -tuln | grep 3306 && echo "MySQL is listening on port 3306"

# ================================
# 6. Firewall Configuration
# ================================
echo "--> Configuring firewall..."
sudo apt-get install -y firewalld > /dev/null
sudo systemctl enable --now firewalld

for ip in 192.168.100.11 192.168.100.12 192.168.100.13; do
    sudo firewall-cmd --permanent --zone=public \
        --add-rich-rule="rule family='ipv4' source address='${ip}' port protocol='tcp' port='3306' accept"
done

sudo firewall-cmd --reload

echo "--- Database Server Provisioning Complete ✓ ---"