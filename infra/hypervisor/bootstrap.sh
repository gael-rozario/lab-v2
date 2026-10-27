#!/usr/bin/env bash
# One-time setup of a fresh Debian host as a libvirt hypervisor for lab VMs
# (used for hp-prodesk1 / 192.168.0.198, which hosts kube-master).
#
# Run on the host as a sudo-capable user, FROM THE PHYSICAL CONSOLE: the br0
# step moves the host's IP from the NIC onto a bridge and drops SSH sessions.
# `systemctl restart networking` hung when switching to the bridge live; a
# reboot after writing the config is the reliable way to apply it.
#
# Prereq: VT-x/AMD-V enabled in BIOS (egrep -c '(vmx|svm)' /proc/cpuinfo > 0).
set -euo pipefail

sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils rsync
sudo usermod -aG libvirt,kvm "$USER"

# Bridge br0 over the primary NIC. bridge_hw pins the bridge to the NIC's MAC
# so the router's DHCP reservation for the host still matches.
NIC=$(ip -o route get 1.1.1.1 | awk '{print $5}')
MAC=$(cat "/sys/class/net/$NIC/address")
if [ "$NIC" != "br0" ]; then
  [ -n "$NIC" ] && [ -n "$MAC" ] || { echo "could not detect NIC/MAC" >&2; exit 1; }
  sudo cp /etc/network/interfaces /etc/network/interfaces.bak
  sudo tee /etc/network/interfaces >/dev/null <<EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

iface $NIC inet manual

auto br0
iface br0 inet dhcp
    bridge_ports $NIC
    bridge_stp off
    bridge_fd 0
    bridge_hw $MAC
EOF
  echo "br0 configured over $NIC ($MAC) - reboot to apply"
fi

# virt-aa-helper doesn't add pool-backed (<source pool= volume=>) disks or their
# backing chain to the per-VM AppArmor profile, which is how terraform-libvirt
# attaches them, so QEMU gets "Permission denied" opening the qcow2. Allow the
# pool's images explicitly.
sudo mkdir -p /etc/apparmor.d/local/abstractions
sudo tee /etc/apparmor.d/local/abstractions/libvirt-qemu >/dev/null <<'EOF'
/var/lib/libvirt/images/debian-12-genericcloud-amd64.qcow2 rk,
/var/lib/libvirt/images/kube-master.qcow2 rwk,
EOF
sudo systemctl reload apparmor

# Debian doesn't create libvirt's default storage pool
if ! virsh -c qemu:///system pool-info default >/dev/null 2>&1; then
  sudo virsh pool-define-as default dir --target /var/lib/libvirt/images
  sudo virsh pool-build default
  sudo virsh pool-start default
  sudo virsh pool-autostart default
fi
