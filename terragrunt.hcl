locals {
  state_base_path = abspath("${get_repo_root()}/../lab-tf-state/terraform/v2")
}

generate "backend" {
  path      = "backend_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "local" {
        path = "${local.state_base_path}/${path_relative_to_include()}/terraform.tfstate"
      }
    }
  EOF
}
