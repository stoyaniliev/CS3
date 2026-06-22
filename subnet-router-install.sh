#!/bin/bash
set -eux
# IP forwarding is required so this node can route mesh traffic to the RDS subnet.
cat > /etc/sysctl.d/99-tailscale.conf <<SYSCTL
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL
sysctl -p /etc/sysctl.d/99-tailscale.conf
curl -fsSL https://tailscale.com/install.sh | sh
