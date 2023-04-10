terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

variable "pve_api_url" {
  type        = string
  description = "PVE API URL"
}

locals {
  vm_group_name = lookup(var.vm_group_names, terraform.workspace, var.vm_group_name_default)

  virtual_machines = [
    {
      ip_address  = "${var.vm_ip_prefix}1"
      name        = "vm${local.vm_group_name}-1"
      target_node = var.target_nodes[0]
      vm2clone    = "vm-4-tf-1"
    },
    # EXPERIMENT BLOCK 1 
    #    {
    #      ip_address  = "${var.vm_ip_prefix}3"
    #      name        = "vm${local.vm_group_name}-3"
    #      target_node = var.target_nodes[1]
    #      vm2clone    = "vm-4-tf-2"
    #    },
    {
      ip_address  = "${var.vm_ip_prefix}2"
      name        = "vm${local.vm_group_name}-2"
      target_node = var.target_nodes[1]
      vm2clone    = "vm-4-tf-2"
    }
  ]
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

output "vm_ids" {
  value = [for o in proxmox_vm_qemu.light_vm : o.id]
  #
  # value = proxmox_vm_qemu.light_vm[*].id # (same but using Splat expressions
  # 
  # #   https://developer.hashicorp.com/terraform/language/expressions/splat
  # # )
}

resource "proxmox_vm_qemu" "light_vm" {

  for_each = {
    for index, vm in local.virtual_machines :
    vm.name => vm # Perfect, since VM names also need to be unique
    # EXPERIMENT BLOCK 2:
    # index => vm # (unique but not perfect, since index will change frequently)


    # uuid() => vm (do NOT do this! gets recreated everytime)
  }

  name        = each.value.name
  target_node = each.value.target_node

  desc = "A test for using terraform and cloudinit"

  # The destination resource pool for the new VM
  pool = var.pool

  # The template name to clone this vm from
  clone      = each.value.vm2clone
  full_clone = true
  oncreate   = true

  # Activate QEMU agent for this VM
  agent = 1

  os_type = "cloud-init"
  cores   = var.cores
  sockets = 1
  vcpus   = 0
  cpu     = var.cpu
  memory  = var.memory
  scsihw  = "virtio-scsi-pci"

  # Setup the disk
  disk {
    size     = var.disk_size
    type     = "virtio"
    storage  = var.disk_storage
    iothread = 1
    discard  = "on"
    format   = "qcow2"
  }

  # Setup the network interface and assign a vlan tag: 256
  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Setup the ip address using cloud-init.
  # Keep in mind to use the CIDR notation for the ip.
  ipconfig0  = "ip=${each.value.ip_address}/16,gw=${var.gateway}"
  nameserver = var.nameserver
}
