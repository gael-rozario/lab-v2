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
  model          = "gpt-oss:20b"
  context_length = 16384
  storage_size   = "50Gi"
  storage_class  = "longhorn-r1"
}
