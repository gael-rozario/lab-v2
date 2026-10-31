include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace    = "hermes"
  llm_base_url = "http://litellm.litellm.svc.cluster.local:4000/v1"
  model          = "qwen3.8"
  # Kept 16384 tokens below llama-cpp's context_size (65536) to absorb the
  # ~14K of tool-schema tokens Hermes omits from its own estimate. See
  # llama-cpp/terragrunt.hcl for the backend-side sizing rationale.
  context_length = 49152

  # telegram_allowed_users comes from TF_VAR_telegram_allowed_users (env)

  storage_class      = "longhorn"
  vault_secret_mount = "secret"
  vault_secret_path  = "hermes"
  vault_role         = "hermes"
}
