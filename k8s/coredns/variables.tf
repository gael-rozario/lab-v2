variable "chart_version" {
  type    = string
  default = "1.46.1"
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "replica_count" {
  description = "CoreDNS replica count — kept >1 with topologySpreadConstraints so a single node failure doesn't take out cluster DNS"
  type        = number
  default     = 2
}

variable "cluster_dns_ip" {
  description = "ClusterIP kubelet's --cluster-dns points at on every node — must match exactly, every pod's resolv.conf is hardcoded to it"
  type        = string
  default     = "10.43.0.10"
}
