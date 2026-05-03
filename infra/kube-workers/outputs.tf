output "workers" {
  description = "Worker VM names and MAC addresses — check router DHCP leases for assigned IPs"
  value = {
    for name, w in var.workers :
    name => w.mac
  }
}
