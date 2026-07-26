include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace = "gaelr-com"
  hostnames = ["gaelr.com", "dev.gaelr.com", "staging.gaelr.com"]

  storage_size  = "20Gi"
  storage_class = "longhorn"
}
