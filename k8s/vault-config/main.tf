# Codifies the Vault kubernetes-auth reviewer so logins can't silently break:
#   1. a NON-EXPIRING legacy SA-token Secret for the Vault server SA, and
#   2. auth/kubernetes/config pointed at that token.
#
# Uses the apply-time `vault` CLI (like the rest of Vault's config in this repo),
# so VAULT_TOKEN must be in the environment when running `terragrunt apply`
# (VAULT_ADDR is supplied below). Re-running re-applies the config idempotently.
resource "null_resource" "kubernetes_auth_reviewer" {
  triggers = {
    namespace       = var.vault_namespace
    server_sa       = var.vault_server_sa
    reviewer_secret = var.reviewer_secret_name
    kubernetes_host = var.kubernetes_host
  }

  provisioner "local-exec" {
    environment = {
      VAULT_ADDR      = var.vault_addr
      VAULT_NS        = var.vault_namespace
      SERVER_SA       = var.vault_server_sa
      REVIEWER_SECRET = var.reviewer_secret_name
      KUBERNETES_HOST = var.kubernetes_host
    }
    command = <<-EOT
      set -e

      # 1. Non-expiring SA-token Secret for the Vault server SA
      kubectl -n "$VAULT_NS" apply -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: $REVIEWER_SECRET
        namespace: $VAULT_NS
        annotations:
          kubernetes.io/service-account.name: $SERVER_SA
      type: kubernetes.io/service-account-token
      EOF

      # 2. Wait for the token controller to populate the token
      for i in $(seq 1 30); do
        kubectl -n "$VAULT_NS" get secret "$REVIEWER_SECRET" -o jsonpath='{.data.token}' 2>/dev/null | grep -q . && break
        sleep 2
      done

      JWT=$(kubectl -n "$VAULT_NS" get secret "$REVIEWER_SECRET" -o jsonpath='{.data.token}' | base64 -d)
      CA=$(kubectl -n "$VAULT_NS" get secret "$REVIEWER_SECRET" -o jsonpath='{.data.ca\.crt}' | base64 -d)

      # 3. Point Vault's kubernetes auth at the non-expiring reviewer
      vault write auth/kubernetes/config \
        kubernetes_host="$KUBERNETES_HOST" \
        token_reviewer_jwt="$JWT" \
        kubernetes_ca_cert="$CA" \
        disable_iss_validation=true
    EOT
  }
}
