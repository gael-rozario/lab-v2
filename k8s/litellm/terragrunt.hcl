include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace          = "litellm"
  internal_subdomain = "int"
  host_prefix        = "llm"
  model              = "gpt-oss:20b"
  model_name         = "gpt-oss"
  ollama_endpoint    = "http://ollama.ollama.svc.cluster.local:11434"
  gateway_name       = "eg-internal"
  gateway_namespace  = "envoy-gateway-system"
  vault_secret_mount = "secret"
  vault_secret_path  = "litellm"
  vault_role         = "litellm"
}
