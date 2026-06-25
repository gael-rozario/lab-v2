variable "chart_version" {
  type    = string
  default = "1.63.0"
}

variable "namespace" {
  type    = string
  default = "ollama"
}

variable "gpu_node" {
  description = "Hostname of the GPU node to schedule Ollama on"
  type        = string
  default     = "worker1"
}

variable "runtime_class" {
  description = "RuntimeClass for the nvidia container runtime"
  type        = string
  default     = "nvidia"
}

variable "model" {
  description = "Ollama model pulled on startup (qwen2.5-coder:14b fits 16GB; use :7b for more context headroom)"
  type        = string
  default     = "qwen2.5-coder:14b"
}

variable "context_length" {
  description = "Default context window (OLLAMA_CONTEXT_LENGTH). KV cache is pre-allocated for this at load."
  type        = number
  default     = 16384
}

variable "num_parallel" {
  description = "Concurrent request slots. 1 = KV cache is exactly one context (no NxKV multiplication). Keep 1 for single-user to guarantee GPU fit."
  type        = number
  default     = 1
}

variable "flash_attention" {
  description = "Enable flash attention (required for KV cache quantization, trims overhead)"
  type        = bool
  default     = true
}

variable "kv_cache_type" {
  description = "KV cache quantization: f16 (none), q8_0 (half), or q4_0 (quarter). Lower = more context fits."
  type        = string
  default     = "q8_0"
}

variable "storage_size" {
  description = "PVC size for model blobs"
  type        = string
  default     = "50Gi"
}

variable "storage_class" {
  description = "StorageClass for models (single-replica Longhorn, created by this module)"
  type        = string
  default     = "longhorn-r1"
}

variable "model_replica_count" {
  description = "Longhorn replicas for model storage (1 = no redundancy; models are re-downloadable)"
  type        = number
  default     = 1
}
