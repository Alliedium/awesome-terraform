variable "workspace_params" {
  type = map(object({
    vm = object({
      master_name_spec = string,
      agent_name_spec  = string,
      base_name_spec = string,
      n_masters      = number,
      n_agents       = number,
      start_ip       = string,
      cores          = optional(number, 2),
      cpu            = optional(string, "kvm64"),
      memory         = optional(number, 2048),
      gateway        = string,
      nameserver     = string,
      disk_size      = string,
      disk_storage   = string,
      pool           = string,
      target_nodes   = list(string),
      bridge         = string
    }),
    pve_api_url = string
  }))
  description = <<EOF
    (Required) vm.master_name_spec  - name template with a single placeholder
       corresponding to sequential VM id, passed directly to
       https://developer.hashicorp.com/terraform/language/functions/format  

    (Required) vm.agent_name_spec - same as vm.master_name_spec but for 
       the base VM (the VM from which to clone to create the new VM).

    (Required) vm.base_name_spec - same as vm.agent_name_spec but for
       the base VM (the VM from which to clone to create the new VM).

    (Required) vm.n_masters      - number of K8s nodes to create 
    (Required) vm.n_agents       - number of K8s nodes to create 

    (Required) vm.start_ip       - IP address of the first VM, all other VMs' IP addresses will be calculated by
       incrementing the last octet by 1.

    (Optional) vm.cores          - number of CPU cores
    (Optional) vm.cpu            - cpu type
    (Optional) vm.memory         - RAM size
    (Required) vm.gateway        - gateway for VM
    (Required) vm.nameserver     - DNS server for VM 
    (Required) vm.disk_size      - disk size 
    (Required) vm.disk_storage   - name of Proxmox storage for the disk
    (Required) vm.pool           - name of Proxmox pool
    (Required) vm.target_nodes   - Proxmox target nodes
    (Required) vm.bridge         - network bridge

    (Required) pve_api_url       - Proxmox API endpoint url
  EOF
}

# Unfortunately, we have to repeat type definition here,
# see https://github.com/hashicorp/terraform/issues/30386
variable "workspace_default_params" {
  type = object({
    vm = object({
      master_name_spec = string,
      agent_name_spec  = string,
      base_name_spec = string,
      n_masters      = number,
      n_agents       = number,
      start_ip       = string,
      cores          = optional(number, 2),
      cpu            = optional(string, "kvm64"),
      memory         = optional(number, 2048),
      gateway        = string,
      nameserver     = string,
      disk_size      = string,
      disk_storage   = string,
      pool           = string,
      target_nodes   = list(string),
      bridge         = string
    }),
    pve_api_url = string
  })
}

variable "vm_ci_user" { 
  type = string
  description = "cloud-init user for provisioning"
  sensitive = true
}

variable "vm_ci_password" {
  type = string
  description = "cloud-init user's password"
  sensitive = true
}

variable "vm_ci_ssh_pub_key_path" {
 type = string
 description = "cloud-init user's public ssh key"
 sensitive = true
}
    
