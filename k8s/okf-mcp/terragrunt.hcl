include "root" {
  path = find_in_parent_folders()
}

include "k8s" {
  path = "${get_repo_root()}/k8s/common.hcl"
}

inputs = {
  namespace     = "okf-mcp"
  notebook_name = "second-brain"
  hostname      = "notes-mcp-sb.int.gaelrozario.com"

  storage_class      = "longhorn"
  vault_secret_mount = "secret"
  vault_secret_path  = "okf-mcp"
  vault_role         = "okf-mcp"
}
