locals {
  kubeconfig_path = get_env("KUBECONFIG", "~/.kube/config")
}

generate "providers" {
  path      = "providers_gen.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "helm" {
      kubernetes {
        config_path = pathexpand("${local.kubeconfig_path}")
      }
    }
  EOF
}
