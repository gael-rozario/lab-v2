include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace         = "llama-cpp"
  hf_repo           = "ggml-org/gpt-oss-20b-GGUF"
  hf_quant          = ""
  served_model_name = "gpt-oss"
  context_size      = 65536
  extra_args        = ["--reasoning-format", "auto", "--chat-template-kwargs", "{\"reasoning_effort\": \"low\"}", "--temp", "1.0", "--top-p", "1.0"]
  n_gpu_layers      = 99
  runtime_class     = "nvidia"
  storage_size      = "50Gi"
  storage_class     = "longhorn-r1"
}
