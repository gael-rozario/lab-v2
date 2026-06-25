include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  vault_namespace      = "vault"
  vault_server_sa      = "vault"
  reviewer_secret_name = "vault-token-reviewer"
  kubernetes_host      = "https://kubernetes.default.svc:443"
  vault_addr           = "https://vault.gaelrozario.com"
}
