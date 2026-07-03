# RuntimeClass mapping pods to the containerd "nvidia" runtime that k3s auto-wired
# (via nvidia-container-toolkit installed in the worker cloud-init).
resource "null_resource" "runtime_class" {
  triggers = {
    handler = var.runtime_class
  }

  provisioner "local-exec" {
    environment = {
      HANDLER = var.runtime_class
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: node.k8s.io/v1
      kind: RuntimeClass
      metadata:
        name: $HANDLER
      handler: $HANDLER
      EOF
    EOT
  }
}

# Mark the GPU node so the chart's default affinity selects it. There's no
# node-feature-discovery here, so we set the chart's documented force-label
# directly (an empty-affinity override gets dropped by the helm provider).
resource "null_resource" "gpu_node_label" {
  triggers = {
    node = var.gpu_node
  }

  provisioner "local-exec" {
    environment = {
      NODE = var.gpu_node
    }
    command = "kubectl label node $NODE nvidia.com/gpu.present=true --overwrite"
  }
}

# NVIDIA device plugin — advertises nvidia.com/gpu. The chart's default affinity
# matches the GPU node via the nvidia.com/gpu.present label set above.
resource "helm_release" "nvidia_device_plugin" {
  depends_on = [null_resource.runtime_class, null_resource.gpu_node_label]

  name             = "nvidia-device-plugin"
  repository       = "https://nvidia.github.io/k8s-device-plugin"
  chart            = "nvidia-device-plugin"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [<<-YAML
    runtimeClassName: ${var.runtime_class}
    # The GPU node is tainted dedicated=ai:NoSchedule; the device plugin MUST run
    # there to advertise nvidia.com/gpu, so it tolerates the taint.
    tolerations:
      - key: dedicated
        operator: Equal
        value: ai
        effect: NoSchedule
  YAML
  ]
}
