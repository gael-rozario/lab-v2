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
  # Hermes HARD-rejects any context_length < 64000 at startup, so the backend
  # must truly serve >=64K. This model's KV cache is small (heavy GQA): at 80K,
  # q8 KV + flash attention + the IQ3 weights measure ~14-15GB on the GPU, which
  # FITS on the 16GB card with no expert offload. (Full --cpu-moe was tried and
  # removed: it works but tanks prefill to ~34 tok/s — a ~16 min wait on Hermes'
  # ~33K prompt. If 80K ever OOMs, add "--n-cpu-moe", "8" to offload just a few
  # expert layers rather than all of them.)
  #
  # 80K (not 64K): Hermes' token estimate runs ~14K low (it omits tool schemas),
  # so its declared 64K window lands ~78K on the wire. The backend sits above
  # that at 80K so real requests don't overrun.
  context_size = 81920
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
