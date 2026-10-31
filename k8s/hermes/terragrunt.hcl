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
  # MUST be >= 64000 - Hermes refuses to start below that (49152 broke it).
  # Kept 16384 tokens below llama-cpp's context_size (81920) to absorb the
  # ~14K of tool-schema tokens Hermes omits from its own estimate. See
  # llama-cpp/terragrunt.hcl for the backend-side sizing rationale.
  context_length = 65536
  # -> chat_template_kwargs.reasoning_effort on every request (Hermes'
  # /reasoning isn't forwarded to custom endpoints). low cut reasoning ~35% vs
  # the server's medium on a test prompt, same answer.
  reasoning_effort = "low"

  # telegram_allowed_users comes from TF_VAR_telegram_allowed_users (env)

  storage_class      = "longhorn"
  vault_secret_mount = "secret"
  vault_secret_path  = "hermes"
  vault_role         = "hermes"
}
