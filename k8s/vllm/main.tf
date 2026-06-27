# vLLM serving an AWQ coder model with native tool-calling. ClusterIP only —
# LiteLLM points at it. Swap models by changing `model`/`served_model_name` and
# re-applying (vLLM redeploys with the new model).
resource "helm_release" "vllm" {
  name             = "vllm"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 900

  values = [<<-YAML
    image: ${var.image}
    model: ${var.model}
    servedModelName: ${var.served_model_name}
    toolParser: ${var.tool_parser}
    maxModelLen: "${var.max_model_len}"
    gpuMemoryUtilization: "${var.gpu_memory_utilization}"
    runtimeClassName: ${var.runtime_class}
    gpuNodeLabel: ${var.gpu_node_label}
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
  YAML
  ]
}
