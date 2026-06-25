include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  vault_chart_version = "0.29.1"
  vault_namespace     = "vault"
  vault_ip            = "192.168.0.243"
  cluster_issuer      = "letsencrypt-prod"
  storage_size        = "10Gi"
  replica_count       = 3
}
