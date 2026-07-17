# Namespace + ServiceAccount + Vault auth + secret sync (VSO), mirroring
# lab-v2/k8s/okf-mcp (the second-brain instance) and hermes.
# Vault role/policy/secret are configured out-of-band (see apply notes):
#   secret/okf-mcp-third-brain -> { github_token }
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
        name: okf-mcp
        namespace: $NAMESPACE
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultAuth
      metadata:
        name: okf-mcp
        namespace: $NAMESPACE
      spec:
        method: kubernetes
        mount: kubernetes
        kubernetes:
          role: $VAULT_ROLE
          serviceAccount: okf-mcp
      ---
      apiVersion: secrets.hashicorp.com/v1beta1
      kind: VaultStaticSecret
      metadata:
        name: okf-mcp-secret
        namespace: $NAMESPACE
      spec:
        type: kv-v2
        mount: $VAULT_MOUNT
        path: $VAULT_PATH
        destination:
          name: okf-mcp-secret
          create: true
        vaultAuthRef: okf-mcp
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
        kubectl get secret okf-mcp-secret -n $NAMESPACE >/dev/null 2>&1 && exit 0
        sleep 5
      done
      echo "timed out waiting for okf-mcp-secret (check Vault role/policy/secret)" >&2
      exit 1
    EOT
  }
}

resource "helm_release" "okf_mcp_third_brain" {
  depends_on = [null_resource.wait_for_secret]

  name             = "okf-mcp-third-brain"
  # Reuses the second-brain instance's chart directly — it's fully generic
  # (values-driven), so there's no reason to fork/duplicate it per notebook.
  chart            = "${path.module}/../okf-mcp/chart"
  namespace        = var.namespace
  create_namespace = false
  wait             = false
  timeout          = 300

  values = [<<-YAML
    image: ${var.image}
    serviceAccountName: okf-mcp
    notebookName: ${var.notebook_name}
    secretName: okf-mcp-secret
    persistentVolume:
      size: ${var.storage_size}
      storageClass: ${var.storage_class}
    httpRoute:
      hostnames:
        - ${var.hostname}
  YAML
  ]
}
