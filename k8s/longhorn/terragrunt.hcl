include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  longhorn_chart_version = "1.7.2"
  longhorn_namespace     = "longhorn-system"
  replica_count          = 3
}
