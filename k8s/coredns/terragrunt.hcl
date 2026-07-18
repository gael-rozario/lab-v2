include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  chart_version  = "1.46.1"
  namespace      = "kube-system"
  replica_count  = 2
  cluster_dns_ip = "10.43.0.10"
}
