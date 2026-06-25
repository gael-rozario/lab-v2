resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = var.cert_manager_namespace
  create_namespace = true
  wait             = true
  timeout          = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "null_resource" "cloudflare_secret" {
  depends_on = [helm_release.cert_manager]

  triggers = {
    namespace = var.cert_manager_namespace
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE        = var.cert_manager_namespace
      CLOUDFLARE_TOKEN = var.cloudflare_token
    }
    command = <<-EOT
      kubectl create secret generic cloudflare-api-token \
        --namespace=$NAMESPACE \
        --from-literal=api-token=$CLOUDFLARE_TOKEN \
        --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }
}

resource "null_resource" "cluster_issuers" {
  depends_on = [null_resource.cloudflare_secret]

  triggers = {
    email     = var.letsencrypt_email
    namespace = var.cert_manager_namespace
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.cert_manager_namespace
      EMAIL     = var.letsencrypt_email
      DOMAIN    = var.domain
    }
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-staging
      spec:
        acme:
          server: https://acme-staging-v02.api.letsencrypt.org/directory
          email: $EMAIL
          privateKeySecretRef:
            name: letsencrypt-staging-key
          solvers:
            - dns01:
                cloudflare:
                  apiTokenSecretRef:
                    name: cloudflare-api-token
                    key: api-token
      ---
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: $EMAIL
          privateKeySecretRef:
            name: letsencrypt-prod-key
          solvers:
            - dns01:
                cloudflare:
                  apiTokenSecretRef:
                    name: cloudflare-api-token
                    key: api-token
      EOF
    EOT
  }
}
