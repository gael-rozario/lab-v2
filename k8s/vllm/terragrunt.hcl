include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace              = "vllm"
  model                  = "Qwen/Qwen2.5-Coder-14B-Instruct-AWQ"
  served_model_name      = "qwen2.5-coder"
  tool_parser            = "hermes"
  max_model_len          = 16384
  gpu_memory_utilization = 0.90
  runtime_class          = "nvidia"
  storage_class          = "longhorn-r1"
}
