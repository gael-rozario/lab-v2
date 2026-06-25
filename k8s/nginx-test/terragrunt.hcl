include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace          = "nginx-test"
  internal_subdomain = "int"
  gateway_name       = "eg-internal"
  gateway_namespace  = "envoy-gateway-system"
}
