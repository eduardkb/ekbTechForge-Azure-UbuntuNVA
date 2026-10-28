#!/usr/bin/env bash
set -euo pipefail

APP_CIDR="10.20.1.0/24"
DATA_CIDR="10.30.1.0/24"

export DEBIAN_FRONTEND=noninteractive

# Install iptables and persistent rule support
apt-get update
apt-get install -y iptables iptables-persistent

# Enable IPv4 forwarding persistently
cat >/etc/sysctl.d/99-azure-nva.conf <<'EOF'
net.ipv4.ip_forward=1
EOF

sysctl --system

# Configure forwarding policy
iptables -N NVA_FORWARD 2>/dev/null || true
iptables -F NVA_FORWARD

iptables -C FORWARD -j NVA_FORWARD 2>/dev/null ||
  iptables -I FORWARD 1 -j NVA_FORWARD

iptables -A NVA_FORWARD \
  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permit traffic between the two spokes
iptables -A NVA_FORWARD \
  -s "$APP_CIDR" -d "$DATA_CIDR" -j ACCEPT

iptables -A NVA_FORWARD \
  -s "$DATA_CIDR" -d "$APP_CIDR" -j ACCEPT

# Permit DNS and outbound HTTP/HTTPS
for CIDR in "$APP_CIDR" "$DATA_CIDR"; do
  iptables -A NVA_FORWARD -s "$CIDR" \
    -p udp --dport 53 -j ACCEPT

  iptables -A NVA_FORWARD -s "$CIDR" \
    -p tcp --dport 53 -j ACCEPT

  iptables -A NVA_FORWARD -s "$CIDR" \
    -p tcp -m multiport --dports 80,443 -j ACCEPT
done

# Deny all other forwarded traffic
iptables -A NVA_FORWARD -j DROP

# Configure source NAT for public IPv4 destinations
iptables -t nat -N NVA_POSTROUTING 2>/dev/null || true
iptables -t nat -F NVA_POSTROUTING

iptables -t nat -C POSTROUTING -j NVA_POSTROUTING 2>/dev/null ||
  iptables -t nat -I POSTROUTING 1 -j NVA_POSTROUTING

for CIDR in "$APP_CIDR" "$DATA_CIDR"; do
  iptables -t nat -A NVA_POSTROUTING \
    -s "$CIDR" ! -d 10.0.0.0/8 \
    -j MASQUERADE
done

# Persist rules across reboots
netfilter-persistent save

echo "NVA forwarding and firewall rules configured."
echo "IPv4 forwarding: $(sysctl -n net.ipv4.ip_forward)"
iptables -S NVA_FORWARD
iptables -t nat -S NVA_POSTROUTING
