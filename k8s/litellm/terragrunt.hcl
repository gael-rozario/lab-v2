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
  model              = "gpt-oss"
  model_name         = "gpt-oss"
  backend_endpoint   = "http://llama-cpp.llama-cpp.svc.cluster.local:8080/v1"
  gateway_name       = "eg-internal"
  gateway_namespace  = "envoy-gateway-system"
  vault_secret_mount = "secret"
  vault_secret_path  = "litellm"
  vault_role         = "litellm"
}
