output "vm_name" {
  value = libvirt_domain.kube_master.name
}

output "bridge_mac" {
  description = "MAC address — check router DHCP leases for the assigned IP"
  value       = var.bridge_mac
}
