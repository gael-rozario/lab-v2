variable "domain" {
  description = "Root domain (e.g. gaelrozario.com); from TF_VAR_domain"
  type        = string
}

variable "internal_subdomain" {
  description = "Internal subdomain, matching the internal gateway (e.g. 'int')"
  type        = string
  default     = "int"
}

variable "namespace" {
  type    = string
  default = "nginx-test"
}

variable "gateway_name" {
  description = "Internal Gateway the HTTPRoute attaches to"
  type        = string
  default     = "eg-internal"
}

variable "gateway_namespace" {
  type    = string
  default = "envoy-gateway-system"
}
