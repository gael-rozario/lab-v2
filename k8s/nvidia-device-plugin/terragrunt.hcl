include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  chart_version = "0.19.3"
  namespace     = "nvidia-device-plugin"
  gpu_node      = "worker1"
  runtime_class = "nvidia"
}
