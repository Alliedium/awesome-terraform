pool         = "infra-e10v9"
vm_ip_prefix = "10.109.1.1"
bridge       = "e10v9"
nameserver   = "10.109.1.1"
gateway      = "10.109.1.1"
disk_size    = "4G"
disk_storage = "black-nfs-0"
target_nodes = ["arctic16", "arctic20"]

vm_group_names = {
  default     = "-tf-clone"
  production  = "-tf-clone-prod"
  import-test = "-4-tf"
}

vm_group_name_default = "-tf-clone-unk"
