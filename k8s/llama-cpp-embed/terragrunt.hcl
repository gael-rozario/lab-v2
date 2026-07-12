include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace         = "llama-cpp-embed"
  hf_repo           = "nomic-ai/nomic-embed-text-v1.5-GGUF"
  hf_quant          = "F16"
  served_model_name = "nomic-embed-text"
  context_size      = 2048
  extra_args        = ["--pooling", "mean"]
  storage_size      = "5Gi"
  storage_class     = "longhorn-r1"
}
