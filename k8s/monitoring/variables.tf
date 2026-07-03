variable "domain" {
  description = "Root domain (e.g. gaelrozario.com); from TF_VAR_domain"
  type        = string
}

variable "internal_subdomain" {
  description = "Internal subdomain matching the eg-internal gateway"
  type        = string
  default     = "int"
}

variable "grafana_host_prefix" {
  description = "Hostname prefix => <prefix>.<internal_subdomain>.<domain>"
  type        = string
  default     = "grafana"
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "kps_chart_version" {
  description = "kube-prometheus-stack chart version"
  type        = string
  default     = "87.2.1"
}

variable "dcgm_chart_version" {
  description = "NVIDIA dcgm-exporter chart version"
  type        = string
  default     = "4.8.2"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (from TF_VAR_grafana_admin_password)"
  type        = string
  sensitive   = true
}

variable "runtime_class" {
  description = "RuntimeClass for the nvidia container runtime (DCGM exporter needs the GPU)"
  type        = string
  default     = "nvidia"
}

variable "storage_class" {
  description = "StorageClass for Prometheus + Grafana PVCs (Longhorn so the data survives reschedule onto worker2/3)"
  type        = string
  default     = "longhorn"
}

variable "prometheus_storage_size" {
  description = "PVC size for Prometheus TSDB"
  type        = string
  default     = "20Gi"
}

variable "grafana_storage_size" {
  description = "PVC size for Grafana (dashboards, sqlite db)"
  type        = string
  default     = "5Gi"
}

variable "gpu_taint" {
  description = "Taint on the GPU node that AI workloads tolerate; key=value:effect"
  type = object({
    key    = string
    value  = string
    effect = string
  })
  default = {
    key    = "dedicated"
    value  = "ai"
    effect = "NoSchedule"
  }
}

variable "gpu_node_label" {
  description = "Node label that marks the GPU node (set by the device-plugin module)"
  type        = string
  default     = "nvidia.com/gpu.present"
}

variable "gateway_name" {
  type    = string
  default = "eg-internal"
}

variable "gateway_namespace" {
  type    = string
  default = "envoy-gateway-system"
}

variable "dcgm_dashboard_gnet_id" {
  description = "grafana.com dashboard id for the NVIDIA DCGM exporter board"
  type        = number
  default     = 12239
}

variable "dcgm_dashboard_revision" {
  type    = number
  default = 2
}
