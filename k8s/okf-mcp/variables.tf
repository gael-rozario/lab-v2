variable "namespace" {
  type    = string
  default = "okf-mcp"
}

variable "image" {
  description = "okf-mcp image"
  type        = string
  default     = "ghcr.io/gael-rozario/okf-mcp:latest"
}

variable "notebook_name" {
  description = "Which gbrain notebook this instance is scoped to (access is controlled by which instance/hostname an agent is pointed at, not per-request auth)"
  type        = string
  default     = "second-brain"
}

variable "hostname" {
  description = "Internal hostname this instance is reachable at"
  type        = string
  default     = "notes-mcp-sb.int.gaelrozario.com"
}

variable "storage_size" {
  description = "PVC size for the gbrain/notebook git clone"
  type        = string
  default     = "2Gi"
}

variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "vault_secret_mount" {
  description = "Vault KV-v2 mount"
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Vault KV path holding github_token (a fine-grained PAT with read/write on gbrain, second-brain, third-brain)"
  type        = string
  default     = "okf-mcp"
}

variable "vault_role" {
  description = "Vault kubernetes auth role bound to the okf-mcp ServiceAccount"
  type        = string
  default     = "okf-mcp"
}
