variable "chart_version" {
  type    = string
  default = "0.19.3"
}

variable "namespace" {
  type    = string
  default = "nvidia-device-plugin"
}

variable "gpu_node" {
  description = "Hostname of the GPU node to pin the device plugin to"
  type        = string
  default     = "worker1"
}

variable "runtime_class" {
  description = "RuntimeClass / containerd handler name that k3s wired for the nvidia runtime"
  type        = string
  default     = "nvidia"
}
