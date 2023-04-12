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
  n_vms = 2
  vm_ip_subnet_parts = split("/", var.vm_start_ip)
  last_octet = tonumber(split(".",local.vm_ip_subnet_parts[0])[3])
  bits2add = 32 - tonumber(local.vm_ip_subnet_parts[1])
  netmask4replace = format("/%s",local.vm_ip_subnet_parts[1])

  vm_group_name = lookup(var.vm_group_names, terraform.workspace, var.vm_group_name_default)
  vm_sec_ids = range(0,local.n_vms)
  vm_sec_pos_ids = [for id in local.vm_sec_ids: id + 1]
  vm_names = formatlist("vm${local.vm_group_name}-%d", local.vm_sec_pos_ids)
  vm2clone_names = formatlist("vm-4-tf-%d", local.vm_sec_pos_ids)
}

output "vm_ids" {
  value = [for o in module.masters : o.id]
  #
  # value = servers[*].id # (same but using Splat expressions
  # 
  # #   https://developer.hashicorp.com/terraform/language/expressions/splat
  # # )
}

module "masters" {

  source = "./modules/k8s_master_node"

  for_each = zipmap(local.vm_names, local.vm_sec_ids)

  name        = each.key
  target_node = var.target_nodes[each.value]

  pool = var.pool

  vm2clone   = local.vm2clone_names[each.value]

  cores   = var.cores
  cpu     = var.cpu
  memory  = var.memory

  disk_size    = var.disk_size
  disk_storage = var.disk_storage
  bridge       = var.bridge

  # Setup the ip address using cloud-init.
  # Keep in mind to use the CIDR notation for the ip.
  ip_address = replace(cidrsubnet(var.vm_start_ip,local.bits2add,local.last_octet+each.value),"/32",local.netmask4replace)
  gateway    = var.gateway
  nameserver = var.nameserver
}
