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

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname       = each.key
    ssh_public_key = local.ssh_public_key
    k3s_master_ip  = var.k3s_master_ip
    k3s_token      = var.k3s_token
    gpu            = each.value.gpu
  })

  network_config = <<-NETCFG
    version: 2
    ethernets:
      id0:
        match:
          macaddress: "${each.value.mac}"
        dhcp4: true
  NETCFG
}

resource "libvirt_domain" "worker" {
  for_each = var.workers

  name      = each.key
  memory    = each.value.gpu ? var.gpu_memory_mb : var.memory_mb
  vcpu      = each.value.gpu ? var.gpu_vcpus : var.vcpus
  autostart = true

  # GPU passthrough requires a Q35/PCIe topology and UEFI (OVMF) firmware so
  # the card's large BARs can be mapped. Non-GPU workers keep provider defaults.
  machine  = each.value.gpu ? "q35" : null
  firmware = each.value.gpu ? var.ovmf_code_path : null

  cpu {
    mode = "host-passthrough"
  }

  dynamic "nvram" {
    for_each = each.value.gpu ? [1] : []
    content {
      file     = "/var/lib/libvirt/qemu/nvram/${each.key}_VARS.fd"
      template = var.ovmf_vars_template
    }
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

  # PCI passthrough of the GPU — injected into the domain XML only for the
  # GPU worker (the provider has no native hostdev block).
  dynamic "xml" {
    for_each = each.value.gpu ? [1] : []
    content {
      xslt = templatefile("${path.module}/gpu-hostdev.xsl.tftpl", {
        domain    = var.gpu_pci.domain
        bus       = var.gpu_pci.bus
        slot      = var.gpu_pci.slot
        functions = var.gpu_pci.functions
      })
    }
  }
}
