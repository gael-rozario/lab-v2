# Namespace + ServiceAccount + Vault auth + secret sync (VSO), mirroring litellm.
# Vault role/policy/secret are configured out-of-band (see apply notes):
#   secret/hermes -> { telegram_bot_token, llm_api_key }
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
        name: hermes
        namespace: $NAMESPACE
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultAuth
      metadata:
        name: hermes
        namespace: $NAMESPACE
      spec:
        method: kubernetes
        mount: kubernetes
        kubernetes:
          role: $VAULT_ROLE
          serviceAccount: hermes
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultStaticSecret
      metadata:
        name: hermes-key
        namespace: $NAMESPACE
      spec:
        type: kv-v2
        mount: $VAULT_MOUNT
        path: $VAULT_PATH
        destination:
          name: hermes-secret
          create: true
        vaultAuthRef: hermes
      EOF
    EOT
  }
}

resource "null_resource" "wait_for_secret" {
  depends_on = [null_resource.vso]

  provisioner "local-exec" {
    environment = {
      NAMESPACE = var.namespace
    }
    command = <<-EOT
      for i in $(seq 1 60); do
        kubectl get secret hermes-secret -n $NAMESPACE >/dev/null 2>&1 && exit 0
        sleep 5
      done
      echo "timed out waiting for hermes-secret (check Vault role/policy/secret)" >&2
      exit 1
    EOT
  }
}

resource "helm_release" "hermes" {
  depends_on = [null_resource.wait_for_secret]

  name             = "hermes"
  chart            = "${path.module}/chart"
  namespace        = var.namespace
  create_namespace = false
  wait             = false
  timeout          = 300

  values = [<<-YAML
    image: ${var.image}
    serviceAccountName: hermes
    llmBaseUrl: ${var.llm_base_url}
    model: ${var.model}
    contextLength: ${var.context_length}
    telegramAllowedUsers: "${var.telegram_allowed_users}"
    secretName: hermes-secret
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
  YAML
  ]
}
