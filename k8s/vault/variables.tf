variable "vault_chart_version" {
  type = string
}

variable "vault_namespace" {
  type    = string
  default = "vault"
}

variable "vault_ip" {
  description = "MetalLB IP assigned to the Vault LoadBalancer service"
  type        = string
  default     = "192.168.0.243"
}

variable "domain" {
  description = "Root domain (e.g. gaelrozario.com)"
  type        = string
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for Vault TLS"
  type        = string
  default     = "letsencrypt-prod"
}

variable "cloudflare_token" {
  description = "Cloudflare API token with DNS:Edit permission"
  type        = string
  sensitive   = true
}

variable "storage_size" {
  description = "Longhorn volume size per Vault replica"
  type        = string
  default     = "10Gi"
}

variable "replica_count" {
  description = "Number of Vault HA replicas"
  type        = number
  default     = 3
}
