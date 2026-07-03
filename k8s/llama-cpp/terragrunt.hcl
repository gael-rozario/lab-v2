include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace         = "llama-cpp"
  hf_repo           = "unsloth/gemma-4-26B-A4B-it-GGUF"
  hf_quant          = "UD-IQ3_XXS"
  served_model_name = "gemma4"
  # MoE analog of the prior qwen3.6 pick: 3.8B active / 25.2B total params,
  # UD-IQ3_XXS weights measure ~11.4GB (near-identical to qwen3.6's 11.5GB at
  # the same quant tier), leaving ~4.6GB of the 16GB card for KV cache + CUDA
  # overhead. Unlike qwen3.6, Gemma 4's per-token KV-cache size on this card
  # isn't verified yet, so context starts at Hermes' hard floor (64K) rather
  # than the 80K margin qwen3.6 could prove out. Raise only after confirming
  # VRAM headroom; if it doesn't fit, prefer "--no-kv-offload" (moves KV cache
  # to system RAM, frees VRAM, costs throughput) over raising quant/dropping ngl.
  #
  # Requires a llama.cpp build with the Gemma 4 tool-call parser (PEP grammar,
  # ggml-org/llama.cpp PR #21326 + tokenizer fix #21343) — merged well before
  # this config was written, but if tool_calls don't come through structured,
  # check the image tag is recent enough.
  context_size = 65536
  extra_args = [
    "--temp", "1.0", "--top-p", "0.95", "--top-k", "64",
    "--flash-attn", "on",
    "--cache-type-k", "q8_0",
    "--cache-type-v", "q8_0",
  ]
  n_gpu_layers      = 99
  runtime_class     = "nvidia"
  storage_size      = "50Gi"
  storage_class     = "longhorn-r1"
}
