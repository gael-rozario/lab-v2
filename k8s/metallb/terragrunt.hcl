include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  metallb_chart_version   = "0.14.9"
  metallb_namespace       = "metallb-system"
  metallb_ip_address_pool = "192.168.0.240-192.168.0.250"
}
