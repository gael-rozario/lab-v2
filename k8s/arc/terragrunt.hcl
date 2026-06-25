include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  arc_controller_chart_version = "0.10.1"
  arc_runner_chart_version     = "0.10.1"
  arc_namespace                = "arc-system"
  min_runners                  = 0
  max_runners                  = 5

  repos = {
    "portfolio" = "https://github.com/gael-rozario/portfolio"
    "lab-v2"    = "https://github.com/gael-rozario/lab-v2"
    "blog"      = "https://github.com/gael-rozario/blog"
  }
}
