include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace         = "llama-cpp"
  hf_repo           = "unsloth/Qwen3.6-35B-A3B-GGUF"
  hf_quant          = "UD-IQ3_XXS"
  served_model_name = "qwen3.6"
  context_size      = 32768
  # 32K KV at f16 won't fit alongside the IQ3 weights on 16GB; q8 KV + flash
  # attention halves the KV footprint so Hermes' ~18.7K prompt fits.
  extra_args = [
    "--reasoning-format", "auto",
    "--temp", "0.6", "--top-p", "0.95", "--top-k", "20",
    "--flash-attn", "on",
    "--cache-type-k", "q8_0",
    "--cache-type-v", "q8_0",
  ]
  n_gpu_layers      = 99
  runtime_class     = "nvidia"
  storage_size      = "50Gi"
  storage_class     = "longhorn-r1"
}
