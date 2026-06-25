include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace          = "monitoring"
  internal_subdomain = "int"
  grafana_host_prefix = "grafana"
  kps_chart_version  = "87.2.1"
  dcgm_chart_version = "4.8.2"
  runtime_class      = "nvidia"
  gateway_name       = "eg-internal"
  gateway_namespace  = "envoy-gateway-system"
}
