variable "vso_chart_version" {
  type = string
}

variable "vso_namespace" {
  type    = string
  default = "vault-secrets-operator-system"
}

variable "domain" {
  description = "Root domain (e.g. gaelrozario.com)"
  type        = string
}
