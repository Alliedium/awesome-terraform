variable "pool" {
  type = string
}
variable "vm_ip_prefix" {
  type = string
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

