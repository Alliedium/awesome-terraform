terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = local.wparams.pve_api_url
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
  master_name_spec  = local.wparams.vm.master_name_spec
  agent_name_spec   = local.wparams.vm.agent_name_spec
  base_vm_name_spec = local.wparams.vm.base_name_spec
  n_masters         = local.wparams.vm.n_masters
  n_agents          = local.wparams.vm.n_agents
  vm_start_ip       = local.wparams.vm.start_ip

  # separate IP address from the mask 
  #     "10.109.1.11/20" -> ["10.109.1.11", "20"]
  vm_ip_subnet_parts = split("/", local.vm_start_ip)
  #
  # 20
  vm_ip_subnet_n_bits = tonumber(local.vm_ip_subnet_parts[1])
  # extract the free part of IP nas a number 
  #
  #   join("",formatlist("%.8b",split(".","10.109.1.11"))) -> "00001010011011010000000100001011"
  #   substr("00001010011011010000000100001011",20,32) -> "000100001011"
  #   parseint("000100001011",2) -> 267
  #
  vm_ip_free_part = parseint(
    substr(
      join(
        "",
	formatlist(
	  "%.8b",
	  split(
	    ".",
	    local.vm_ip_subnet_parts[0]
	  )
	)
      ),
      local.vm_ip_subnet_n_bits,
      32
    ),
    2
  )
  # calculate number of "free" bits in subnet
  #     20 -> 12 
  bits2add = 32 - local.vm_ip_subnet_n_bits 
  # form a string which will replace "/32"
  #     ["10.109.1.11", "24"] -> "/24"
  netmask4replace = format("/%s", local.vm_ip_subnet_parts[1])

  ip_addresses = [
    for k in range(0, local.n_masters + local.n_agents):
      replace(
        cidrsubnet(
          local.vm_start_ip,
          local.bits2add,
          local.vm_ip_free_part + k 
        ),
        "/32",
        local.netmask4replace
      )
  ]
  # 
  master_seq_ids     = range(0, local.n_masters)
  master_seq_pos_ids = [for id in local.master_seq_ids : id + 1]

  agent_seq_ids     = range(0, local.n_agents)
  agent_seq_pos_ids = [for id in local.agent_seq_ids : id + 1]

  master_vm_names = formatlist(local.master_name_spec, local.master_seq_pos_ids)
  agent_vm_names  = formatlist(local.agent_name_spec, local.agent_seq_pos_ids)

  base_vm_names = [
    for id_sec in range(
      1,
      max(local.n_masters, local.n_agents) + 1
    ) : format(local.base_vm_name_spec, id_sec)
  ]
}

output "master_ids" {
  value = [for o in module.masters : o.id]
}

output "master_ips" {
  value = slice(local.ip_addresses,0,local.n_masters) 
}

output "agents_ids" {
  value = [for o in module.agents : o.id]
}

output "agent_ips" {
  value = slice(
    local.ip_addresses,
    local.n_masters,
    local.n_masters+local.n_agents
  ) 
}

output "ids" {
  value = [for o in merge(module.masters, module.agents) : o.id]
}


module "masters" {

  source = "./modules/k8s_master_node"

  for_each = zipmap(local.master_vm_names, local.master_seq_ids)

  name        = each.key
  target_node = local.wparams.vm.target_nodes[each.value]
  pool = local.wparams.vm.pool
  base_vm_name = local.base_vm_names[each.value]
  cores  = local.wparams.vm.cores
  cpu    = local.wparams.vm.cpu
  memory = local.wparams.vm.memory
  disk_size    = local.wparams.vm.disk_size
  disk_storage = local.wparams.vm.disk_storage
  bridge       = local.wparams.vm.bridge
  ip_address = local.ip_addresses[each.value]
  gateway    = local.wparams.vm.gateway
  nameserver = local.wparams.vm.nameserver
}

module "agents" {

  source = "./modules/k8s_agent_node"

  for_each = zipmap(local.agent_vm_names, local.agent_seq_ids)

  name        = each.key
  target_node = local.wparams.vm.target_nodes[each.value]
  pool = local.wparams.vm.pool
  base_vm_name = local.base_vm_names[each.value]
  cores  = local.wparams.vm.cores
  cpu    = local.wparams.vm.cpu
  memory = local.wparams.vm.memory
  disk_size    = local.wparams.vm.disk_size
  disk_storage = local.wparams.vm.disk_storage
  bridge       = local.wparams.vm.bridge
  ip_address = local.ip_addresses[each.value + local.n_masters]
  gateway    = local.wparams.vm.gateway
  nameserver = local.wparams.vm.nameserver
}
