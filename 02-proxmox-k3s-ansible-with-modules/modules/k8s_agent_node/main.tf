variable "base_vm_name" {
  type        = string
  description = "VM to clone"
}

variable "target_node" {
  type = string
}

variable "pool" {
  type = string
}
variable "name" {
  type = string
}
variable "cores" {
  type = string
}

variable "cpu" {
  type = string
}
variable "memory" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "disk_storage" {
  type = string
}
variable "bridge" {
  type = string
}
variable "nameserver" {
  type = string
}
variable "ip_address" {
  type = string
}
variable "gateway" {
  type = string
}

variable "ciuser" { 
  type = string
  description = "cloud-init user for provisioning"
  sensitive = true
}

variable "cipassword" {
  type = string
  description = "cloud-init user's password"
  sensitive = true
}

variable "sshkeys" {
 type = string
 description = "Newline delimited list of SSH public keys to add to authorized keys file for the cloud-init user"
 sensitive = true
}

output "id" {
  value = module.k8s_agent_node.id
}

output "ip" {
  value = module.k8s_agent_node.ip
}

module "k8s_agent_node" {
  source = "../light_vm"

  desc = "K8s agent node"

  base_vm_name = var.base_vm_name
  target_node = var.target_node
  pool = var.pool
  name = var.name
  cores = var.cores
  cpu   = var.cpu
  memory = var.memory
  disk_size = var.disk_size
  disk_storage = var.disk_storage
  bridge  = var.bridge
  nameserver = var.nameserver
  ip_address = var.ip_address
  gateway = var.gateway
  ciuser = var.ciuser
  cipassword = var.cipassword
  sshkeys = var.sshkeys
}
