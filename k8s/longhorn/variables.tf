variable "longhorn_chart_version" {
  type    = string
}

variable "longhorn_namespace" {
  type    = string
  default = "longhorn-system"
}

variable "replica_count" {
  description = "Default number of replicas for Longhorn volumes"
  type        = number
  default     = 3
}
