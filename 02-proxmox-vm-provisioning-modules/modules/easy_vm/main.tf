terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

variable "vm2clone" {
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

output "id" {
  value = proxmox_vm_qemu.light_vm.id
}

resource "proxmox_vm_qemu" "light_vm" {

  name        = var.name
  target_node = var.target_node

  desc = "A test for using terraform and cloudinit"

  # The destination resource pool for the new VM
  pool = var.pool

  # The template name to clone this vm from
  clone      = var.vm2clone
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
  ipconfig0  = "ip=${var.ip_address}/16,gw=${var.gateway}"
  nameserver = var.nameserver
}
