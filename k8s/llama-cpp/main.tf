# llama.cpp server (--jinja) serving a GGUF coder model with NATIVE tool-calling.
# --jinja makes it use the model's embedded Jinja chat template + llama.cpp's
# tool-call parsers, producing structured tool_calls where Ollama leaked JSON.
# ClusterIP only — LiteLLM points at it. Swap models by changing hf_repo/hf_quant
# and re-applying.
resource "helm_release" "llama_cpp" {
  name             = "llama-cpp"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 900

  values = [<<-YAML
    image: ${var.image}
    hfRepo: "${var.hf_repo}"
    hfQuant: "${var.hf_quant}"
    servedModelName: ${var.served_model_name}
    contextSize: "${var.context_size}"
    extraArgs: ${jsonencode(var.extra_args)}
    nGpuLayers: "${var.n_gpu_layers}"
    runtimeClassName: ${var.runtime_class}
    gpuNodeLabel: ${var.gpu_node_label}
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
  YAML
  ]
}
