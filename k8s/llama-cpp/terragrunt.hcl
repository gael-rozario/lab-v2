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
  hf_repo           = "unsloth/Qwen3.8-27B-GGUF"
  hf_quant          = "UD-Q3_K_XL"
  served_model_name = "qwen3.8"
  # Qwen3.8-27B (2026-08), dense 27B, replaced gemma-4-26B-A4B (MoE) for
  # stronger coding/agentic results. UD-Q3_K_XL = 13.1GB; Q4 quants (15.4GB+)
  # leave no room for KV on 16GB.
  #
  # Hybrid attention (qwen3_5 arch): only 16 of 64 layers are full attention
  # (4 KV heads x 256 head_dim), the rest linear attention with a fixed-size
  # state - so KV is ~34KB/token at q8_0. Estimate: 13.1GB weights + ~2.2GB KV
  # at 65536 + ~1GB buffers = ~16.2GB, i.e. tight. 98304 (the gemma4 setting)
  # would need ~3.4GB KV and does not fit. Re-check nvidia-smi after applying
  # before raising.
  #
  # --no-mmproj: it's a VL model and -hf would otherwise pull + load the vision
  # projector into VRAM; nothing here sends images.
  # Sampling = Qwen's thinking-mode settings, except temp 0.7 (Qwen says 1.0)
  # for more consistent commands in agent use (Hermes, OpenCode). Don't go
  # below ~0.6: near-greedy decoding in thinking mode risks repetition loops.
  # Only a default - clients sending their own temperature override it.
  #
  # reasoning_effort: the chat template supports xhigh (default) / medium / low.
  # At xhigh a one-line kubectl question burned 4000+ reasoning tokens (~140s at
  # ~28 tok/s on the 5060 Ti) without answering; medium answered correctly in
  # ~630 tokens / ~23s. Clients can still override per request via
  # chat_template_kwargs.
  context_size = 65536
  extra_args = [
    "--temp", "0.7", "--top-p", "0.95", "--top-k", "20", "--min-p", "0.0",
    "--chat-template-kwargs", "{\"reasoning_effort\":\"medium\"}",
    "--no-mmproj",
    "--flash-attn", "on",
    "--cache-type-k", "q8_0",
    "--cache-type-v", "q8_0",
  ]
  n_gpu_layers  = 99
  runtime_class = "nvidia"
  storage_size  = "24Gi"
  storage_class = "longhorn-r1"
}
