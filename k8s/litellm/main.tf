locals {
  hostname = "${var.host_prefix}.${var.internal_subdomain}.${var.domain}"
}

# Namespace + ServiceAccount + Vault auth + master-key sync via vault-secrets-operator.
# Mirrors the arc module pattern. The Vault kubernetes-auth role and the KV secret
# itself are configured in Vault out-of-band (see module README / apply notes).
resource "null_resource" "vso" {
  triggers = {
    namespace   = var.namespace
    vault_mount = var.vault_secret_mount
    vault_path  = var.vault_secret_path
    vault_role  = var.vault_role
  }

  provisioner "local-exec" {
    environment = {
      NAMESPACE   = var.namespace
      VAULT_MOUNT = var.vault_secret_mount
      VAULT_PATH  = var.vault_secret_path
      VAULT_ROLE  = var.vault_role
    }
    command = <<-EOT
      kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: litellm
        namespace: $NAMESPACE
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultAuth
      metadata:
        name: litellm
        namespace: $NAMESPACE
      spec:
        method: kubernetes
        mount: kubernetes
        kubernetes:
          role: $VAULT_ROLE
          serviceAccount: litellm
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultStaticSecret
      metadata:
        name: litellm-key
        namespace: $NAMESPACE
      spec:
        type: kv-v2
        mount: $VAULT_MOUNT
        path: $VAULT_PATH
        destination:
          name: litellm-secret
          create: true
        vaultAuthRef: litellm
      EOF
    EOT
  }
}

# Block until VSO has synced the master key into a k8s Secret (bounded to ~5m).
resource "null_resource" "wait_for_secret" {
  depends_on = [null_resource.vso]

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.namespace
    }
    command = <<-EOT
      for i in $(seq 1 60); do
        kubectl get secret litellm-secret -n $NAMESPACE >/dev/null 2>&1 && exit 0
        sleep 5
      done
      echo "timed out waiting for litellm-secret (check Vault role/policy/secret)" >&2
      exit 1
    EOT
  }
}

resource "helm_release" "litellm" {
  depends_on = [null_resource.wait_for_secret]

  name             = "litellm"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = false
  wait             = false
  timeout          = 600

  values = [<<-YAML
    image: ${var.image}
    serviceAccountName: litellm
    masterKeySecret:
      name: litellm-secret
      key: ${var.master_key_field}
    backend:
      endpoint: ${var.backend_endpoint}
      model: ${var.model}
    modelName: ${var.model_name}
    gateway:
      name: ${var.gateway_name}
      namespace: ${var.gateway_namespace}
    hostname: ${local.hostname}
  YAML
  ]
}
