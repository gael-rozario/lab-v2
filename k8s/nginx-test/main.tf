resource "helm_release" "nginx_test" {
  name             = "nginx-test"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [<<-YAML
    hostname: "nginx.${var.internal_subdomain}.${var.domain}"
    gateway:
      name: ${var.gateway_name}
      namespace: ${var.gateway_namespace}
  YAML
  ]
}
