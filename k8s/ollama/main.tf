# Single-replica Longhorn StorageClass for model blobs. Models are re-downloadable,
# so 3x replication would just waste space; data-locality keeps the replica on the
# GPU node where Ollama runs.
resource "null_resource" "model_storage_class" {
  triggers = {
    name     = var.storage_class
    replicas = tostring(var.model_replica_count)
  }

  provisioner "local-exec" {
    environment = {
      SC_NAME  = var.storage_class
      REPLICAS = tostring(var.model_replica_count)
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: storage.k8s.io/v1
      kind: StorageClass
      metadata:
        name: $SC_NAME
      provisioner: driver.longhorn.io
      allowVolumeExpansion: true
      reclaimPolicy: Delete
      volumeBindingMode: Immediate
      parameters:
        numberOfReplicas: "$REPLICAS"
        staleReplicaTimeout: "30"
        dataLocality: "best-effort"
      EOF
    EOT
  }
}

# Ollama serving Qwen Coder on the GPU node. ClusterIP only — exposure/auth
# (LiteLLM + internal gateway) comes in a later module.
resource "helm_release" "ollama" {
  depends_on = [null_resource.model_storage_class]

  name             = "ollama"
  repository       = "https://helm.otwld.com/"
  chart            = "ollama"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [<<-YAML
    ollama:
      gpu:
        enabled: true
        type: nvidia
        number: 1
      models:
        pull:
          - ${var.model}
    runtimeClassName: ${var.runtime_class}
    nodeSelector:
      kubernetes.io/hostname: ${var.gpu_node}
    persistentVolume:
      enabled: true
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
    service:
      type: ClusterIP
    extraEnv:
      - name: OLLAMA_CONTEXT_LENGTH
        value: "${var.context_length}"
      # KV cache is pre-allocated as context_length x num_parallel at load; keep
      # num_parallel=1 so it can't multiply and spill to CPU.
      - name: OLLAMA_NUM_PARALLEL
        value: "${var.num_parallel}"
      - name: OLLAMA_FLASH_ATTENTION
        value: "${var.flash_attention ? "1" : "0"}"
      - name: OLLAMA_KV_CACHE_TYPE
        value: "${var.kv_cache_type}"
  YAML
  ]
}
