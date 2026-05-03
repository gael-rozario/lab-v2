include "root" {
  path = find_in_parent_folders()
}

inputs = {
  workers = {
    worker1 = { mac = "52:54:00:4e:0b:04" }
    worker2 = { mac = "52:54:00:07:41:56" }
    worker3 = { mac = "52:54:00:a1:b2:c3" }
  }
}
