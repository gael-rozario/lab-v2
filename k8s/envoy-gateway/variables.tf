variable "envoy_gateway_chart_version" {
  type = string
}

variable "envoy_gateway_namespace" {
  type    = string
  default = "envoy-gateway-system"
}

variable "domain" {
  description = "Root domain for wildcard TLS cert (e.g. gaelrozario.com)"
  type        = string
}

variable "internal_subdomain" {
  description = "Subdomain under domain for internal-only services, e.g. 'int' => *.int.<domain>"
  type        = string
  default     = "int"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for wildcard TLS"
  type        = string
  default     = "letsencrypt-prod"
}

variable "cloudflare_token" {
  description = "Cloudflare API token with DNS:Edit permission"
  type        = string
  sensitive   = true
}

variable "internal_gateway_ip" {
  description = "Pinned MetalLB IP for the internal gateway (the *.int wildcard points here)"
  type        = string
  default     = "192.168.0.244"
}

