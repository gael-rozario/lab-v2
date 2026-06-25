include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  cert_manager_chart_version = "v1.19.4"
  cert_manager_namespace     = "cert-manager"
}
