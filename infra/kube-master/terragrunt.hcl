include "root" {
  path = find_in_parent_folders()
}

inputs = {
  # hp-prodesk1 (replaced the laptop as master host 2026-10)
  master_libvirt_uri  = "qemu+ssh://gael@192.168.0.198/system?keyfile=/home/gael/.ssh/id_ed25519&no_verify=1"
  vm_name             = "kube-master"
  bridge_mac          = "52:54:00:ca:19:03"
  memory_mb           = 4096
  vcpus               = 2
  disk_size_bytes     = 214748364800
  debian_image_source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}
