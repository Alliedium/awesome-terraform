workspace_params = {
  default = {
    vm = {
      name_spec      = "vm-tf-default-%d"
      base_name_spec = "base-vm-tf-%d"
      count          = 2
      start_ip       = "10.109.1.11/24"
      pool           = "infra-e10v9"
      cores          = 2
      memory         = 2048
      bridge         = "e10v9"
      nameserver     = "10.109.1.1"
      gateway        = "10.109.1.1"
      disk_size      = "5G"
      disk_storage   = "black-nfs-0"
      target_nodes   = ["arctic16", "arctic20"]
    },
    pve_api_url = "https://192.168.2.95:8006/api2/json"
  }
  production = {
    vm = {
      name_spec      = "vm-tf-prod-%d"
      base_name_spec = "base-vm-tf-%d"
      count          = 3
      start_ip       = "10.109.1.21/24"
      pool           = "infra-e10v9"
      cpu            = "host"
      cores          = 4
      memory         = 4096
      bridge         = "e10v9"
      nameserver     = "10.109.1.1"
      gateway        = "10.109.1.1"
      disk_size      = "8G"
      disk_storage   = "black-nfs-0"
      target_nodes   = ["arctic16", "arctic20", "blackgrid"]
    },
    pve_api_url = "https://192.168.2.95:8006/api2/json"
  }
}
workspace_default_params = {
  vm = {
    name_spec      = "vm-tf-unk-%d"
    base_name_spec = "base-vm-tf-%d"
    count          = 2
    start_ip       = "10.109.1.51/24"
    pool           = "infra-e10v9"
    cpu            = "kvm64"
    cores          = 2
    memory         = 4096
    bridge         = "e10v9"
    nameserver     = "10.109.1.1"
    gateway        = "10.109.1.1"
    disk_size      = "4G"
    disk_storage   = "black-nfs-0"
    target_nodes   = ["arctic16", "arctic20"]
  },
  pve_api_url = "https://192.168.2.95:8006/api2/json"
}
