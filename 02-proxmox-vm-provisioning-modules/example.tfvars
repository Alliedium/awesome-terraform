workspace_params = {
  default = {
    vm_group_name = "-tf-clone"
    n_vms         = 2
    vm_start_ip   = "10.109.1.11/24"
    pool          = "infra-e10v9"
    cpu           = "kvm64"
    cores         = 2
    memory        = 2048
    bridge        = "e10v9"
    nameserver    = "10.109.1.1"
    gateway       = "10.109.1.1"
    disk_size     = "5G"
    disk_storage  = "black-nfs-0"
    target_nodes  = ["arctic16", "arctic20"]
  }
  production = {
    vm_group_name = "-tf-clone-prod"
    n_vms         = 3
    vm_start_ip   = "10.109.1.21/24"
    pool          = "infra-e10v9"
    cpu           = "host"
    cores         = 4
    memory        = 4096
    bridge        = "e10v9"
    nameserver    = "10.109.1.1"
    gateway       = "10.109.1.1"
    disk_size     = "8G"
    disk_storage  = "black-nfs-0"
    target_nodes  = ["arctic16", "arctic20", "blackgrid"]
  }
}
workspace_default_params = {
  vm_group_name = "-tf-clone-unk"
  n_vms         = 2
  vm_start_ip   = "10.109.1.51/24"
  pool          = "infra-e10v9"
  cpu           = "kvm64"
  cores         = 2
  memory        = 4096
  bridge        = "e10v9"
  nameserver    = "10.109.1.1"
  gateway       = "10.109.1.1"
  disk_size     = "4G"
  disk_storage  = "black-nfs-0"
  target_nodes  = ["arctic16", "arctic20"]
}
