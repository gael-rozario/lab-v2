#!/usr/bin/env bash
# Make hp-prodesk1 (192.168.0.198) a Tailscale subnet router so the homelab is
# reachable remotely (e.g. laptop on mobile Wi-Fi while travelling).
#
# Run on the host as a sudo-capable user; `tailscale up` prints a login URL to
# open in a browser.
#
# Only /32s are advertised, not 192.168.0.0/24: 192.168.0.x is a common default
# on other networks, and on Linux Tailscale's policy routing outranks local
# routes, so a /24 would hijack the remote network's own 192.168.0.x hosts.
#   192.168.0.244  eg-internal gateway -> every *.int.gaelrozario.com app
#   192.168.0.172  kube-master (k3s API :6443, existing kubeconfig works as-is)
#   192.168.0.198  this host (SSH, jump host for anything else)
# Default --snat-subnet-routes means the LAN needs no return routes.
#
# After running, in the admin console (login.tailscale.com):
#   - Machines -> hp-prodesk1 -> Edit route settings: approve the routes
#   - Machines -> hp-prodesk1 -> Disable key expiry (else it drops off in 180d)
#   - DNS: global nameserver 1.1.1.1 + "Override local DNS" -- some hotel/mobile
#     resolvers drop public answers pointing at private IPs (rebind protection),
#     which breaks *.int lookups
#
# Laptop:
#   curl -fsSL https://tailscale.com/install.sh | sh
#   sudo tailscale up --accept-routes
#   (at home: `sudo tailscale set --accept-routes=false` to go direct over LAN)
set -euo pipefail

ROUTES="${ROUTES:-192.168.0.244/32,192.168.0.172/32,192.168.0.198/32}"

# shellcheck source=/dev/null
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${CODENAME}.noarmor.gpg" \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${CODENAME}.tailscale-keyring.list" \
  | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
sudo apt-get update
sudo apt-get install -y tailscale

# Subnet routing needs forwarding; br0 has nf_call_iptables=0, so bridged VM
# traffic is unaffected.
sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

sudo tailscale up --advertise-routes="$ROUTES"
