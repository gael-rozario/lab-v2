variable "namespace" {
  type    = string
  default = "hermes"
}

variable "image" {
  description = "Hermes Agent image"
  type        = string
  default     = "nousresearch/hermes-agent:latest"
}

variable "llm_base_url" {
  description = "OpenAI-compatible endpoint Hermes uses for inference (LiteLLM)"
  type        = string
  default     = "http://litellm.litellm.svc.cluster.local:4000/v1"
}

variable "model" {
  description = "Model name as exposed by LiteLLM"
  type        = string
  default     = "gpt-oss"
}

variable "telegram_allowed_users" {
  description = "Comma-separated Telegram user IDs allowed to use the bot (your id from @userinfobot)"
  type        = string
}

variable "storage_size" {
  description = "PVC size for /opt/data (memories, sessions, logs)"
  type        = string
  default     = "5Gi"
}

variable "storage_class" {
  description = "StorageClass for Hermes data (memories are not re-downloadable -> keep replicated)"
  type        = string
  default     = "longhorn"
}

variable "vault_secret_mount" {
  description = "Vault KV-v2 mount"
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Vault KV path holding telegram_bot_token + llm_api_key"
  type        = string
  default     = "hermes"
}

variable "vault_role" {
  description = "Vault kubernetes auth role bound to the hermes ServiceAccount"
  type        = string
  default     = "hermes"
}
