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
  # --ubatch-size raised to match context_size: the physical batch size
  # (default 512) is the real per-request limit, not -c/n_ctx — a single
  # embedding input over 512 tokens 500s ("increase the physical batch
  # size") well before hitting the 2048 context ceiling.
  extra_args = ["--pooling", "mean", "--ubatch-size", "2048"]
  storage_size      = "5Gi"
  storage_class     = "longhorn-r1"
}
