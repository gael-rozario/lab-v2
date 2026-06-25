include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  vso_chart_version = "0.9.1"
  vso_namespace     = "vault-secrets-operator-system"
}
