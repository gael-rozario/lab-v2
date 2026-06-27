variable "domain" {
  description = "Root domain (e.g. gaelrozario.com); from TF_VAR_domain"
  type        = string
}

variable "internal_subdomain" {
  description = "Internal subdomain matching the eg-internal gateway"
  type        = string
  default     = "int"
}

variable "host_prefix" {
  description = "Hostname prefix => <host_prefix>.<internal_subdomain>.<domain>"
  type        = string
  default     = "llm"
}

variable "namespace" {
  type    = string
  default = "litellm"
}

variable "image" {
  description = "LiteLLM proxy image (non-database variant runs DB-less, master-key auth)"
  type        = string
  default     = "ghcr.io/berriai/litellm:main-stable"
}

variable "model" {
  description = "Backend model name served by llama.cpp (its --alias)"
  type        = string
  default     = "gpt-oss"
}

variable "model_name" {
  description = "Public model name clients request"
  type        = string
  default     = "gpt-oss"
}

variable "backend_endpoint" {
  description = "In-cluster OpenAI-compatible backend endpoint (llama.cpp /v1)"
  type        = string
  default     = "http://llama-cpp.llama-cpp.svc.cluster.local:8080/v1"
}

variable "gateway_name" {
  type    = string
  default = "eg-internal"
}

variable "gateway_namespace" {
  type    = string
  default = "envoy-gateway-system"
}

variable "vault_secret_mount" {
  description = "Vault KV-v2 mount"
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Vault KV path holding the LiteLLM master key"
  type        = string
  default     = "litellm"
}

variable "vault_role" {
  description = "Vault kubernetes auth role bound to the litellm ServiceAccount"
  type        = string
  default     = "litellm"
}

variable "master_key_field" {
  description = "Field within the Vault secret holding the master key"
  type        = string
  default     = "master_key"
}
