variable "arc_controller_chart_version" {
  type = string
}

variable "arc_runner_chart_version" {
  type = string
}

variable "arc_namespace" {
  type    = string
  default = "arc-system"
}

variable "repos" {
  description = "Map of runner name to GitHub repo URL"
  type        = map(string)
}

variable "vault_secret_mount" {
  description = "Vault KV secrets engine mount"
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Path to the GitHub App credentials in Vault"
  type        = string
  default     = "arc/github"
}

variable "min_runners" {
  type    = number
  default = 0
}

variable "max_runners" {
  type    = number
  default = 5
}
