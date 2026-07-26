variable "namespace" {
  type    = string
  default = "gaelr-com"
}

variable "image" {
  description = "Ubuntu LTS + Docker Engine image for the Docker-in-Docker pod"
  type        = string
  default     = "ghcr.io/gael-rozario/gaelr-com-dind:latest"
}

variable "hostnames" {
  description = "Hostnames the HTTPRoute matches on the eg Gateway's http listener"
  type        = list(string)
  default     = ["gaelr.com", "dev.gaelr.com", "staging.gaelr.com"]
}

variable "storage_size" {
  description = "PVC size for /var/lib/docker (nested images/containers/volumes)"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  type    = string
  default = "longhorn"
}
