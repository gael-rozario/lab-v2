include "root" {
  path = find_in_parent_folders()
}

inputs = {
  workers = {
    worker1 = { mac = "52:54:00:4e:0b:04", gpu = true }
    worker2 = { mac = "52:54:00:07:41:56" }
    worker3 = { mac = "52:54:00:a1:b2:c3" }
  }

  # Host RAM upgraded 32GB -> 48GB (2026-07-12): 2GB reserved for the host,
  # remaining 46GB split worker1 +6GB, worker2 +4GB, worker3 +4GB.
  gpu_memory_mb = 22528 # worker1: 16GB -> 22GB
  memory_mb     = 12288 # worker2, worker3: 8GB -> 12GB
}
