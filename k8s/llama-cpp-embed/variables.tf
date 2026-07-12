variable "namespace" {
  type    = string
  default = "llama-cpp-embed"
}

variable "image" {
  description = "llama.cpp server image (CPU build — this instance has no GPU node to itself)."
  type        = string
  default     = "ghcr.io/ggml-org/llama.cpp:server"
}

variable "hf_repo" {
  description = "HuggingFace GGUF repo for the embedding model"
  type        = string
  default     = "nomic-ai/nomic-embed-text-v1.5-GGUF"
}

variable "hf_quant" {
  description = "GGUF quant tag (-hf repo:quant). F16 is ~274MB — trivial size, so no need to trade quality for footprint."
  type        = string
  default     = "F16"
}

variable "served_model_name" {
  description = "Name reported at /v1/models (llama-server --alias); what LiteLLM/clients request"
  type        = string
  default     = "nomic-embed-text"
}

variable "context_size" {
  description = "Context window (-c). This GGUF's trained context is 2048 (n_ctx_train) — llama.cpp caps to it regardless, so setting higher is a no-op."
  type        = number
  default     = 2048
}

variable "extra_args" {
  description = "Model-specific llama-server flags. nomic-embed-text uses mean pooling; --ubatch-size raised to match context_size since the physical batch (default 512) caps single-request input size, not n_ctx."
  type        = list(string)
  default     = ["--pooling", "mean", "--ubatch-size", "2048"]
}

variable "storage_size" {
  description = "PVC for the GGUF download cache. Model is ~300MB; sized with headroom for a future quant swap."
  type        = string
  default     = "5Gi"
}

variable "storage_class" {
  description = "GGUF is re-downloadable from HF -> single-replica StorageClass is fine"
  type        = string
  default     = "longhorn-r1"
}
