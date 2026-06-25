variable "cert_manager_chart_version" {
  type = string
}

variable "cert_manager_namespace" {
  type    = string
  default = "cert-manager"
}

variable "cloudflare_token" {
  description = "Cloudflare API token with DNS:Edit permission"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt notifications"
  type        = string
}

variable "domain" {
  description = "Root domain managed in Cloudflare"
  type        = string
}
