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
  # 40K is the most this 16GB card holds with the IQ3 weights resident (~2.3GB
  # free at 32K). q8 KV + flash attention keep the cache small. Hermes' baseline
  # (system prompt + tool schemas) is ~33K, so 40K is the floor that seats it
  # with a little working room; Hermes' own context_length is set ~14K lower to
  # absorb the tool-schema tokens it doesn't count. If this OOMs, drop to 36864.
  context_size = 40960
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
