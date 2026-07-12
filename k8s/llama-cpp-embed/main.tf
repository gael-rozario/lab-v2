# llama.cpp server (--embedding) serving a small CPU-friendly embedding model
# (nomic-embed-text by default). Pinned to a CPU-only worker via nodeSelector —
# no GPU, no dedicated=ai toleration needed. ClusterIP only; wire into LiteLLM
# the same way the chat llama-cpp instance is.
resource "helm_release" "llama_cpp_embed" {
  name             = "llama-cpp-embed"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 300

  values = [<<-YAML
    image: ${var.image}
    hfRepo: "${var.hf_repo}"
    hfQuant: "${var.hf_quant}"
    servedModelName: ${var.served_model_name}
    contextSize: "${var.context_size}"
    extraArgs: ${jsonencode(var.extra_args)}
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
  YAML
  ]
}
