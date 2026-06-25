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
}
