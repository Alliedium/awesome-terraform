terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

variable "pve_api_url" {
  type = string

}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = var.pve_api_url
  pm_otp          = ""
  pm_log_enable   = true
  pm_log_file     = "terraform-plugin-proxmox.log"
  pm_debug        = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

}

locals {
  wparams = lookup(
    var.workspace_params,
    terraform.workspace,
    var.workspace_default_params
  )
  vm_group_name = local.wparams.vm_group_name
  n_vms         = local.wparams.n_vms
  vm_start_ip   = local.wparams.vm_start_ip

  vm_ip_subnet_parts = split("/", local.vm_start_ip)
  last_octet         = tonumber(split(".", local.vm_ip_subnet_parts[0])[3])
  bits2add           = 32 - tonumber(local.vm_ip_subnet_parts[1])
  netmask4replace    = format("/%s", local.vm_ip_subnet_parts[1])


  vm_sec_ids     = range(0, local.n_vms)
  vm_sec_pos_ids = [for id in local.vm_sec_ids : id + 1]
  vm_names       = formatlist("vm${local.vm_group_name}-%d", local.vm_sec_pos_ids)
  vm2clone_names = formatlist("vm-4-tf-%d", local.vm_sec_pos_ids)
}

output "vm_ids" {
  value = [for o in module.masters : o.id]
}

module "masters" {

  source = "./modules/k8s_master_node"

  for_each = zipmap(local.vm_names, local.vm_sec_ids)

  name        = each.key
  target_node = local.wparams.target_nodes[each.value]

  pool = local.wparams.pool

  vm2clone = local.vm2clone_names[each.value]

  cores  = local.wparams.cores
  cpu    = local.wparams.cpu
  memory = local.wparams.memory

  disk_size    = local.wparams.disk_size
  disk_storage = local.wparams.disk_storage
  bridge       = local.wparams.bridge

  ip_address = replace(
    cidrsubnet(
      local.vm_start_ip,
      local.bits2add,
      local.last_octet + each.value
    ),
    "/32",
    local.netmask4replace
  )
  gateway    = local.wparams.gateway
  nameserver = local.wparams.nameserver
}
