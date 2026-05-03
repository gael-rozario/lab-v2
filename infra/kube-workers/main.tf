provider "libvirt" {
  uri = var.libvirt_uri
}

locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

# Debian 12 genericcloud base image — downloaded once into home-pool on the worker host
resource "libvirt_volume" "debian_base" {
  name   = "debian-12-genericcloud-amd64.qcow2"
  pool   = var.storage_pool
  source = var.debian_image_source
  format = "qcow2"
}

# OS disk per worker: thin overlay on base, 40 GiB
resource "libvirt_volume" "os" {
  for_each = var.workers

  name           = "${each.key}.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.debian_base.id
  size           = var.os_disk_size_bytes
}

# Data disk per worker: blank 160 GiB volume for Longhorn (/dev/vdb)
resource "libvirt_volume" "data" {
  for_each = var.workers

  name   = "${each.key}-data.qcow2"
  pool   = var.storage_pool
  format = "qcow2"
  size   = var.data_disk_size_bytes
}

# cloud-init ISO per worker (network + user config)
resource "libvirt_cloudinit_disk" "worker" {
  for_each = var.workers

  name = "${each.key}-cloudinit.iso"
  pool = var.storage_pool

  user_data = <<-USERDATA
    #cloud-config
    hostname: ${each.key}
    fqdn: ${each.key}.local
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
  USERDATA

  network_config = <<-NETCFG
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
  NETCFG
}

resource "libvirt_domain" "worker" {
  for_each = var.workers

  name      = each.key
  memory    = var.memory_mb
  vcpu      = var.vcpus
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.worker[each.key].id

  # OS disk
  disk {
    volume_id = libvirt_volume.os[each.key].id
  }

  # Data disk for Longhorn — appears as /dev/vdb inside the VM
  disk {
    volume_id = libvirt_volume.data[each.key].id
  }

  # Single bridge interface — no libvirt management network
  network_interface {
    bridge         = "br0"
    mac            = each.value.mac
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
