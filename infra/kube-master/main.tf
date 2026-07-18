provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  network_config = <<-NETCFG
    version: 2
    ethernets:
      id0:
        match:
          macaddress: "${var.bridge_mac}"
        dhcp4: true
  NETCFG

  user_data = <<-USERDATA
    #cloud-config
    hostname: ${var.vm_name}
    fqdn: ${var.vm_name}.local
    manage_etc_hosts: true

    users:
      - name: gael
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        groups: [sudo]
        lock_passwd: false
        ssh_authorized_keys:
          - ${local.ssh_public_key}

    growpart:
      mode: auto
      devices: ["/"]

    resize_rootfs: true

    runcmd:
      - DEBIAN_FRONTEND=noninteractive apt-get update
      - DEBIAN_FRONTEND=noninteractive apt-get install -y open-iscsi nfs-common cryptsetup
      - systemctl daemon-reload
      - echo iscsi_tcp >> /etc/modules
      - modprobe iscsi_tcp
      - systemctl enable iscsid
      - systemctl start iscsid
      # Untainted by default in k3s (unlike kubeadm) — taint explicitly so
      # regular workloads never land on master, including on worker failure.
      - curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_token} sh -s - --disable traefik --disable servicelb --disable local-storage --disable coredns --node-taint node-role.kubernetes.io/control-plane:NoSchedule
  USERDATA
}

# Debian 12 genericcloud base image — downloaded once into the libvirt pool
resource "libvirt_volume" "debian_base" {
  name   = "debian-12-genericcloud-amd64.qcow2"
  pool   = var.storage_pool
  source = var.debian_image_source
  format = "qcow2"
}

# VM disk: thin-provisioned overlay on top of the base image, expanded to 200 GiB
resource "libvirt_volume" "kube_master" {
  name           = "${var.vm_name}.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.debian_base.id
  size           = var.disk_size_bytes
}

# cloud-init ISO attached as a CDROM drive
resource "libvirt_cloudinit_disk" "kube_master" {
  name           = "${var.vm_name}-cloudinit.iso"
  pool           = var.storage_pool
  user_data      = local.user_data
  network_config = local.network_config
}

resource "libvirt_domain" "kube_master" {
  name      = var.vm_name
  memory    = var.memory_mb
  vcpu      = var.vcpus
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.kube_master.id

  disk {
    volume_id = libvirt_volume.kube_master.id
  }

  # Single bridge interface — IP assigned by router via MAC reservation
  network_interface {
    bridge         = "br0"
    mac            = var.bridge_mac
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
