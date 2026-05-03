variable "vm_name" {
  type    = string
}

variable "bridge_mac" {
  description = "MAC address for the bridge interface — IP assigned via router DHCP reservation"
  type        = string
}

variable "memory_mb" {
  type    = number
}

variable "vcpus" {
  type    = number
}

variable "disk_size_bytes" {
  description = "VM disk size in bytes (default 200 GiB)"
  type        = number
}

variable "storage_pool" {
  type    = string
  default = "default"
}

variable "debian_image_source" {
  description = "URL or local path to the Debian 12 genericcloud qcow2 image"
  type        = string
}

variable "ssh_public_key_path" {
  type    = string
}

variable "k3s_token" {
  description = "Pre-shared token for k3s cluster"
  type        = string
  sensitive   = true
}
