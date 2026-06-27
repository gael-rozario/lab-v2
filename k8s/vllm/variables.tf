variable "namespace" {
  type    = string
  default = "vllm"
}

variable "image" {
  description = "vLLM OpenAI-compatible server image (pin for reproducibility)"
  type        = string
  default     = "vllm/vllm-openai:latest"
}

variable "model" {
  description = "HuggingFace model id (AWQ 4-bit to fit 16GB)"
  type        = string
  default     = "Qwen/Qwen2.5-Coder-14B-Instruct-AWQ"
}

variable "served_model_name" {
  description = "Name clients/LiteLLM use to request this model"
  type        = string
  default     = "qwen2.5-coder"
}

variable "tool_parser" {
  description = "vLLM tool-call parser (hermes for Qwen2.5)"
  type        = string
  default     = "hermes"
}

variable "max_model_len" {
  description = "Context window. 14B AWQ on 16GB fits ~16k; raise cautiously."
  type        = number
  default     = 16384
}

variable "gpu_memory_utilization" {
  description = "Fraction of GPU VRAM vLLM reserves (weights + KV)"
  type        = number
  default     = 0.90
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
  description = "PVC for the HuggingFace model cache (so redeploys don't re-download)"
  type        = string
  default     = "30Gi"
}

variable "storage_class" {
  description = "Models are re-downloadable from HF -> single-replica StorageClass is fine"
  type        = string
  default     = "longhorn-r1"
}
