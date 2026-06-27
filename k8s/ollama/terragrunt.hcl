include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  chart_version  = "1.63.0"
  namespace      = "ollama"
  gpu_node       = "worker1"
  runtime_class  = "nvidia"
  model          = "qwen2.5-coder:14b-instruct"
  context_length = 32768
  storage_size   = "50Gi"
  storage_class  = "longhorn-r1"
}
