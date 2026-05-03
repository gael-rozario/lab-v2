variable "libvirt_uri" {
  description = "libvirt connection URI for the worker host (e.g. qemu+ssh://user@hostname/system)"
  type        = string
}

variable "workers" {
  description = "Map of worker VMs — keys become hostnames, IP assigned by router via MAC reservation"
  type = map(object({
    mac = string
  }))
  # Example:
  # workers = {
  #   worker1 = { mac = "52:54:00:4e:0b:04" }
  #   worker2 = { mac = "52:54:00:07:41:56" }
  #   worker3 = { mac = "52:54:00:a1:b2:c3" }
  # }
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "vcpus" {
  type    = number
  default = 4
}

variable "os_disk_size_bytes" {
  description = "OS disk size in bytes (default 40 GiB)"
  type        = number
  default     = 42949672960
}

variable "data_disk_size_bytes" {
  description = "Data disk size in bytes — mounted for Longhorn (default 160 GiB)"
  type        = number
  default     = 171798691840
}

variable "storage_pool" {
  type    = string
  default = "home-pool"
}

variable "debian_image_source" {
  description = "URL or local path to the Debian 12 genericcloud qcow2 image"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
