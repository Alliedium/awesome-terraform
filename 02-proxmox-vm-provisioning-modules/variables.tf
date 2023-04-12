variable "workspace_params" {
  type = map(object({
    vm_group_name = string,
    n_vms         = number
    vm_start_ip   = string,
    cores         = number,
    cpu           = string
    memory        = number,
    gateway       = string,
    nameserver    = string,
    disk_size     = string,
    disk_storage  = string,
    pool          = string
    target_nodes  = list(string)
    bridge        = string
  }))
}
variable "workspace_default_params" {
  type = object({
    vm_group_name = string,
    n_vms         = number,
    vm_start_ip   = string,
    cores         = number,
    cpu           = string
    memory        = number,
    gateway       = string,
    nameserver    = string,
    disk_size     = string,
    disk_storage  = string,
    pool          = string
    target_nodes  = list(string)
    bridge        = string
  })
}
