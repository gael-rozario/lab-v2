resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = var.longhorn_chart_version
  namespace        = var.longhorn_namespace
  create_namespace = true
  wait             = true
  timeout          = 600

  set {
    name  = "defaultSettings.defaultDataPath"
    value = "/var/lib/longhorn"
  }

  set {
    name  = "persistence.defaultClassReplicaCount"
    value = tostring(var.replica_count)
  }

  # Only create the default disk on nodes explicitly labeled for it (workers,
  # via --node-label in infra/kube-workers/cloud-init.yaml.tftpl). kube-master
  # has no dedicated data disk and shouldn't be a storage node.
  set {
    name  = "defaultSettings.createDefaultDiskLabeledNodes"
    value = "true"
  }

  # worker1 (GPU node) is tainted dedicated=ai:NoSchedule. Longhorn must tolerate
  # it so its manager/instance-manager keep running there (worker1 is a storage
  # node — /dev/vdb). NOTE: Longhorn only applies a taint-toleration change when
  # NO volumes are attached, so scale llama-cpp to 0 before applying this.
  set {
    name  = "defaultSettings.taintToleration"
    value = "dedicated=ai:NoSchedule"
  }
}
