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
  pm_api_token_id = local.wsensparams.pm_api_token_id
  pm_api_token_secret = local.wsensparams.pm_api_token_secret
  pm_otp          = ""
  pm_log_enable   = true
  pm_log_file     = "terraform-plugin-proxmox.log"
  pm_debug        = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }

}

module "deepmerge_wparams" {
  source  = "Invicton-Labs/deepmerge/null"
  maps = [
    module.remove_nulls_wparams_def.removed,
    module.remove_nulls_wparams.removed
  ]
}

module "deepmerge_wsensparams" {
  source  = "Invicton-Labs/deepmerge/null"
  maps = [
    module.remove_nulls_wsensparams_def.removed,
    module.remove_nulls_wsensparams.removed
  ]
}

module "remove_nulls_wparams" {
  source = "./modules/wparam-remove-nulls"
  object_with_nulls = lookup(
    var.workspace_params,
    terraform.workspace,
    var.workspace_default_params
  )
}

module "remove_nulls_wsensparams" {
  source = "./modules/wparam-remove-nulls"
  object_with_nulls = lookup(
    var.workspace_sensitive_params,
    terraform.workspace,
    var.workspace_sensitive_default_params
  )
}

module "remove_nulls_wparams_def" {
  source = "./modules/wparam-remove-nulls"
  object_with_nulls = var.workspace_default_params
}

module "remove_nulls_wsensparams_def" {
  source = "./modules/wparam-remove-nulls"
  object_with_nulls = var.workspace_sensitive_default_params
}

locals {

  wparams = module.deepmerge_wparams.merged
  wsensparams = module.deepmerge_wsensparams.merged

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
    for k in range(0, local.n_masters + local.n_agents) :
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

  vm_ci_ssh_private_key_path = trimsuffix(local.wsensparams.vm.ci_ssh_pub_key_path, ".pub")
}

output "master_ids" {
  value = [for o in module.masters : o.id]
}

output "master_ips" {
  value = [for o in module.masters : o.ip]
}

output "agents_ids" {
  value = [for o in module.agents : o.id]
}
output "agents_ips" {
  value = [for o in module.agents : o.ip]
}

output "ids" {
  value = [for o in merge(module.masters, module.agents) : o.id]
}

output "ips" {
  value = [for o in merge(module.masters, module.agents) : o.ip]
}

data "local_file" "vm_ci_ssh_pub_key" {
  filename = local.wsensparams.vm.ci_ssh_pub_key_path
}

output "wsensparams" {
  value = local.wsensparams
  sensitive = true
}

output "wparams" {
  value = local.wparams
}

module "masters" {

  source = "./modules/k8s_master_node"

  for_each = zipmap(local.master_vm_names, local.master_seq_ids)

  name         = each.key
  target_node  = local.wparams.vm.target_nodes[each.value]
  pool         = local.wparams.vm.pool
  base_vm_name = local.base_vm_names[each.value]
  cores        = local.wparams.vm.cores
  cpu          = local.wparams.vm.cpu
  memory       = local.wparams.vm.memory
  disk_size    = local.wparams.vm.disk_size
  disk_storage = local.wparams.vm.disk_storage
  bridge       = local.wparams.vm.bridge
  ip_address   = local.ip_addresses[each.value]
  gateway      = local.wparams.vm.gateway
  nameserver   = local.wparams.vm.nameserver

  ciuser     = local.wsensparams.vm.ci_user
  cipassword = local.wsensparams.vm.ci_password
  sshkeys    = data.local_file.vm_ci_ssh_pub_key.content
}

module "agents" {

  source = "./modules/k8s_agent_node"

  for_each = zipmap(local.agent_vm_names, local.agent_seq_ids)

  name         = each.key
  target_node  = local.wparams.vm.target_nodes[each.value]
  pool         = local.wparams.vm.pool
  base_vm_name = local.base_vm_names[each.value]
  cores        = local.wparams.vm.cores
  cpu          = local.wparams.vm.cpu
  memory       = local.wparams.vm.memory
  disk_size    = local.wparams.vm.disk_size
  disk_storage = local.wparams.vm.disk_storage
  bridge       = local.wparams.vm.bridge
  ip_address   = local.ip_addresses[each.value + local.n_masters]
  gateway      = local.wparams.vm.gateway
  nameserver   = local.wparams.vm.nameserver

  ciuser     = local.wsensparams.vm.ci_user
  cipassword = local.wsensparams.vm.ci_password
  sshkeys    = data.local_file.vm_ci_ssh_pub_key.content
}

resource "local_file" "k3s_ansible_inventory_file" {
  content = templatefile("${path.module}/templates/hosts.yml.tftpl",
    {
      masters                      = module.masters
      agents                       = module.agents
      ansible_user                 = local.wsensparams.vm.ci_user
      ansible_ssh_private_key_file = local.vm_ci_ssh_private_key_path
    }
  )
  filename = "external/k3s-ansible/inventory/terraform/hosts.yml"
}

resource "local_file" "k3s_ansible_group_vars_all" {
  content = templatefile("${path.module}/templates/group_vars-all.yml.tftpl",
    {
      metal_lb_ip_range  = local.wsensparams.metal_lb_ip_range
      apiserver_endpoint = local.wsensparams.apiserver_endpoint
      system_timezone    = local.wsensparams.vm.system_timezone
      k3s_token          = local.wsensparams.k3s_token
      ansible_user       = local.wsensparams.vm.ci_user
    }
  )
  filename = "external/k3s-ansible/inventory/terraform/group_vars/all.yml"
}
