variable "pool" {
  type = string
}
variable "vm_start_ip" {
  type = string
  description = "IP of the first VM in CIDR notation, '192.168.3.11/24' for example"
}
variable "bridge" {
  type = string
}
variable "cpu" {
  type    = string
  default = "host"
}
variable "cores" {
  type    = string
  default = 2
}
variable "memory" {
  type    = string
  default = 4000
}
variable "gateway" {
  type = string
}
variable "nameserver" {
  type = string
}
variable "disk_size" {
  type = string
}
variable "disk_storage" {
  type = string
}
variable "target_nodes" {
  type = list(string)
}
variable "vm_group_names" {
  type = map(string)
}
variable "vm_group_name_default" {
  type = string
}

