include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  envoy_gateway_chart_version = "1.3.0"
  envoy_gateway_namespace     = "envoy-gateway-system"
  cluster_issuer              = "letsencrypt-prod"
  internal_gateway_ip         = "192.168.0.244"
}
