include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace = "llama-cpp"
  # Pinned to what :server-cuda resolved to on 2026-07-20 - floating tag +
  # default IfNotPresent pull policy meant the deployed binary was silently
  # stuck on whatever the GPU node cached at first pull (2026-07-03), with no
  # way to tell from code if newer llama.cpp fixes were actually live. Bump
  # this digest deliberately (re-resolve `server-cuda` on GHCR) when you want
  # to pull in upstream changes.
  image             = "ghcr.io/ggml-org/llama.cpp:server-cuda@sha256:b19cec9fe85f11d001f8911d87bc20a0479bfaf8ab99fd8dcef2258a4fd8c0ab"
  hf_repo           = "unsloth/gemma-4-26B-A4B-it-GGUF"
  hf_quant          = "UD-Q3_K_XL"
  served_model_name = "gemma4"
  # MoE analog of the prior qwen3.6 pick: 3.8B active / 25.2B total params.
  # Upgraded from UD-IQ3_XXS (11.4GB) to UD-Q3_K_XL (12.9GB, same 3-bit tier,
  # less aggressive per-layer quantization) for better attention/MoE-routing
  # precision - a misrouted token picks the wrong experts entirely, so routing
  # precision matters more here than on a dense model. Confirmed via
  # nvidia-smi at context_size=98304, ngl=99: 15461MiB/16311MiB, ~850MiB
  # headroom - fits, but tight. Do not raise context_size further on this
  # quant without dropping something else first (ngl, cache-type, or context).
  #
  # Requires a llama.cpp build with the Gemma 4 tool-call parser (PEP grammar,
  # ggml-org/llama.cpp PR #21326 + tokenizer fix #21343) — merged well before
  # this config was written, but if tool_calls don't come through structured,
  # check the image tag is recent enough.
  #
  # 98304 (raised from 81920): confirmed via nvidia-smi that 81920 actually
  # used 13817MiB/16311MiB, i.e. ~2.4GB of headroom — better than the ~1.8GB
  # this config originally extrapolated, so real KV scaling on this card is
  # cheaper than the linear estimate that picked 81920. Bumped by the same
  # 16384-token step Hermes' declared window keeps below this value (see
  # hermes/terragrunt.hcl), staying conservative rather than chasing the
  # full headroom in one step. Re-check nvidia-smi after applying.
  context_size = 98304
  extra_args = [
    "--temp", "1.0", "--top-p", "0.95", "--top-k", "64",
    "--flash-attn", "on",
    "--cache-type-k", "q8_0",
    "--cache-type-v", "q8_0",
  ]
  n_gpu_layers  = 99
  runtime_class = "nvidia"
  storage_size  = "50Gi"
  storage_class = "longhorn-r1"
}
