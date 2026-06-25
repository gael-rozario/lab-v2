variable "metallb_chart_version" {
  type = string
}

variable "metallb_namespace" {
  type    = string
  default = "metallb-system"
}

variable "metallb_ip_address_pool" {
  description = "IP range for MetalLB to assign (e.g. 192.168.0.240-192.168.0.250)"
  type        = string
}
