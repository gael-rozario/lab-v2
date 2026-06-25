variable "libvirt_uri" {
  description = "libvirt connection URI for the worker host (e.g. qemu+ssh://user@hostname/system)"
  type        = string
}

variable "workers" {
  description = "Map of worker VMs — keys become hostnames, IP assigned by router via MAC reservation"
  type = map(object({
    mac = string
    # When true: PCI passthrough of the GPU, Q35 + UEFI firmware, and GPU sizing.
    gpu = optional(bool, false)
  }))
  # Example:
  # workers = {
  #   worker1 = { mac = "52:54:00:4e:0b:04", gpu = true }
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

variable "k3s_master_ip" {
  description = "IP address of the k3s master node"
  type        = string
}

variable "k3s_token" {
  description = "Pre-shared token for k3s cluster"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# GPU passthrough (applies only to workers with gpu = true)
# ---------------------------------------------------------------------------

variable "gpu_memory_mb" {
  description = "Memory for the GPU worker (overrides memory_mb)"
  type        = number
  default     = 16384
}

variable "gpu_vcpus" {
  description = "vCPUs for the GPU worker (overrides vcpus)"
  type        = number
  default     = 8
}

variable "ovmf_code_path" {
  description = "Path to the OVMF UEFI CODE firmware on the libvirt host (Debian: ovmf package)"
  type        = string
  default     = "/usr/share/OVMF/OVMF_CODE_4M.fd"
}

variable "ovmf_vars_template" {
  description = "Path to the OVMF UEFI VARS template on the libvirt host"
  type        = string
  default     = "/usr/share/OVMF/OVMF_VARS_4M.fd"
}

variable "gpu_pci" {
  description = "Host PCI address (from lspci -nnk) of the GPU functions to pass through"
  type = object({
    domain    = optional(string, "0x0000")
    bus       = string
    slot      = string
    functions = list(string) # one entry per function, e.g. GPU + HDMI audio
  })
  # RTX 5060 Ti on lab-worker: 07:00.0 (GPU) + 07:00.1 (audio)
  default = {
    bus       = "0x07"
    slot      = "0x00"
    functions = ["0x0", "0x1"]
  }
}
