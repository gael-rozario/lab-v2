include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace    = "hermes"
  llm_base_url = "http://litellm.litellm.svc.cluster.local:4000/v1"
  model          = "gemma4"
  context_length = 65536

  # telegram_allowed_users comes from TF_VAR_telegram_allowed_users (env)

  storage_class      = "longhorn"
  vault_secret_mount = "secret"
  vault_secret_path  = "hermes"
  vault_role         = "hermes"
}
