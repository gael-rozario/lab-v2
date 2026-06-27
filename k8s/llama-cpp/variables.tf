variable "namespace" {
  type    = string
  default = "llama-cpp"
}

variable "image" {
  description = "llama.cpp server image (CUDA build). Pin a digest/tag for reproducibility."
  type        = string
  default     = "ghcr.io/ggml-org/llama.cpp:server-cuda"
}

variable "hf_repo" {
  description = "HuggingFace GGUF repo for the model"
  type        = string
  default     = "ggml-org/gpt-oss-20b-GGUF"
}

variable "hf_quant" {
  description = "Optional GGUF quant tag (-hf repo:quant). Leave empty to let llama.cpp pick the repo's default file (e.g. gpt-oss is single-file MXFP4)."
  type        = string
  default     = ""
}

variable "served_model_name" {
  description = "Name reported at /v1/models (llama-server --alias); what LiteLLM/clients request"
  type        = string
  default     = "gpt-oss"
}

variable "context_size" {
  description = "Context window (-c). gpt-oss native is 128k; trimmed to 64k to fit 16GB."
  type        = number
  default     = 65536
}

variable "extra_args" {
  description = "Model-specific llama-server flags (reasoning, sampling, chat-template-kwargs). Set per model in terragrunt."
  type        = list(string)
  default     = ["--reasoning-format", "auto", "--chat-template-kwargs", "{\"reasoning_effort\": \"low\"}", "--temp", "1.0", "--top-p", "1.0"]
}

variable "n_gpu_layers" {
  description = "Layers offloaded to GPU (-ngl). 99 = all on a 14B."
  type        = number
  default     = 99
}

variable "gpu_node_label" {
  description = "Label marking the GPU node (set by the device-plugin module)"
  type        = string
  default     = "nvidia.com/gpu.present"
}

variable "runtime_class" {
  type    = string
  default = "nvidia"
}

variable "storage_size" {
  description = "PVC for the GGUF download cache. Sized to hold multiple models so swaps don't re-download."
  type        = string
  default     = "50Gi"
}

variable "storage_class" {
  description = "GGUFs are re-downloadable from HF -> single-replica StorageClass is fine"
  type        = string
  default     = "longhorn-r1"
}
