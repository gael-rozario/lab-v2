variable "vault_namespace" {
  type    = string
  default = "vault"
}

variable "vault_server_sa" {
  description = "Vault server ServiceAccount (has system:auth-delegator for TokenReview)"
  type        = string
  default     = "vault"
}

variable "reviewer_secret_name" {
  description = "Name of the non-expiring SA-token Secret used as the kubernetes-auth reviewer"
  type        = string
  default     = "vault-token-reviewer"
}

variable "kubernetes_host" {
  type    = string
  default = "https://kubernetes.default.svc:443"
}

variable "vault_addr" {
  description = "Vault API address for the apply-time vault CLI (VAULT_TOKEN must also be in the environment)"
  type        = string
  default     = "https://vault.gaelrozario.com"
}
