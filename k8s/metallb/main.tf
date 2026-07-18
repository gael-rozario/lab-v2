resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = var.metallb_chart_version
  namespace        = var.metallb_namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  # speaker already tolerates the control-plane taint by default
  # (speaker.tolerateMaster, chart default: true) since it must run on
  # every node for L2 announcement to work. controller doesn't get that by
  # default — add it explicitly so IP allocation can still recover onto
  # master if every worker goes down.
  values = [<<-YAML
    controller:
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
  YAML
  ]
}

resource "null_resource" "metallb_config" {
  depends_on = [helm_release.metallb]

  triggers = {
    namespace       = var.metallb_namespace
    ip_address_pool = var.metallb_ip_address_pool
  }

  provisioner "local-exec" {
    environment = {
      METALLB_NAMESPACE       = var.metallb_namespace
      METALLB_IP_ADDRESS_POOL = var.metallb_ip_address_pool
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: metallb.io/v1beta1
      kind: IPAddressPool
      metadata:
        name: default-pool
        namespace: $METALLB_NAMESPACE
      spec:
        addresses:
          - $METALLB_IP_ADDRESS_POOL
      ---
      apiVersion: metallb.io/v1beta1
      kind: L2Advertisement
      metadata:
        name: default
        namespace: $METALLB_NAMESPACE
      spec:
        ipAddressPools:
          - default-pool
      EOF
    EOT
  }
}
