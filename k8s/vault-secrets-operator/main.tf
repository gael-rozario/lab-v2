resource "helm_release" "vso" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  version          = var.vso_chart_version
  namespace        = var.vso_namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [<<-YAML
    defaultVaultConnection:
      enabled: true
      address: https://vault.${var.domain}
      skipTLSVerify: false
  YAML
  ]
}
