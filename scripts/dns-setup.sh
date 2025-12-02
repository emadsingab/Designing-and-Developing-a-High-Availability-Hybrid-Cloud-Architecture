#!/bin/bash
echo "--- Provisioning DNS Server (dns01) ---"

############################################################
# 1. Install Dnsmasq
############################################################
echo "--> Installing Dnsmasq..."
sudo yum install -y dnsmasq > /dev/null

############################################################
# 2. Configure Dnsmasq to listen on the private network
############################################################
echo "--> Configuring Dnsmasq to listen on the private network..."
# Disable default loopback-only bindings if they exist
sudo sed -i '/^interface=lo/s/^/#/' /etc/dnsmasq.conf
sudo sed -i '/^bind-interfaces/s/^/#/' /etc/dnsmasq.conf

# Add custom settings
echo "listen-address=::1,127.0.0.1,192.168.100.30" | sudo tee -a /etc/dnsmasq.conf > /dev/null
echo "address=/applicationx.domain.com/192.168.1.150" | sudo tee -a /etc/dnsmasq.conf > /dev/null
echo "address=/applicationx.domain.com/192.168.100.20" | sudo tee -a /etc/dnsmasq.conf > /dev/null
############################################################
# 3. Start and Enable Dnsmasq
############################################################
echo "--> Starting and Enabling Dnsmasq..."
sudo systemctl start dnsmasq
sudo systemctl enable dnsmasq

############################################################
# 4. Configure Firewall to allow DNS
############################################################
echo "--> Configuring Firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --zone=public --add-service=dns > /dev/null
sudo firewall-cmd --reload

############################################################
# 5. Verify DNS port listening
############################################################
echo "--> Verifying DNS (dnsmasq) port listening:"
if sudo ss -tuln | grep -q ':53'; then
  echo "✓ dnsmasq is listening on port 53 (TCP/UDP)"
else
  echo "✗ dnsmasq is NOT listening on port 53"
fi

echo "--- DNS Server (dns01) Provisioning Complete  ---"
echo " Domain is now available: https://applicationx.domain.com "
