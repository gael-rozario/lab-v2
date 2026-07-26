resource "helm_release" "gaelr_com" {
  name             = "gaelr-com"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [<<-YAML
    image: ${var.image}
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
    httpRoute:
      hostnames:
      %{ for h in var.hostnames ~}
        - ${h}
      %{ endfor ~}
  YAML
  ]
}
