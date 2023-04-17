variable "workspace_params" {
  type = map(object({
    vm = object({
      master_name_spec = optional(string),
      agent_name_spec  = optional(string),
      base_name_spec   = optional(string),
      n_masters        = optional(number),
      n_agents         = optional(number),
      start_ip         = optional(string),
      cores            = optional(number, 2),
      cpu              = optional(string, "kvm64"),
      memory           = optional(number, 2048),
      gateway          = optional(string),
      nameserver       = optional(string),
      disk_size        = optional(string),
      disk_storage     = optional(string),
      pool             = optional(string),
      target_nodes     = optional(list(string)),
      bridge           = optional(string)
    }),
    pve_api_url = optional(string)
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
      master_name_spec = optional(string),
      agent_name_spec  = optional(string),
      base_name_spec   = optional(string),
      n_masters        = optional(number),
      n_agents         = optional(number),
      start_ip         = optional(string),
      cores            = optional(number, 2),
      cpu              = optional(string, "kvm64"),
      memory           = optional(number, 2048),
      gateway          = optional(string),
      nameserver       = optional(string),
      disk_size        = optional(string),
      disk_storage     = optional(string),
      pool             = optional(string),
      target_nodes     = optional(list(string)),
      bridge           = optional(string)
    }),
    pve_api_url = optional(string)
  })
}


variable "workspace_sensitive_params" {
  type = map(object({
    vm = object({
      ci_user             = optional(string),
      ci_password         = optional(string),
      ci_ssh_pub_key_path = optional(string),
      system_timezone     = optional(string)
    }),
    metal_lb_ip_range  = optional(string),
    apiserver_endpoint = optional(string),
    k3s_token          = optional(string)
  }))
  description = <<EOF
    (Optional) vm.ci_user        -  cloud-init user for provisioning
    (Optional) vm.ci_password    -  cloud-init user's password 
    (Optional) vm.ci_ssh_pub_key_path - cloud-init user's public ssh key
    (Optional) vm.system_timezone   - timezone on K3s nodes 
    (Optional) metal_lb_ip_range - Metal LB IP range. Example: '192.168.30.80-192.168.30.90'
    (Optional) apiserver_endpoint - virtual ip-address which will be configured on each master
    (Optional) k3s_token -  used to allow masters talk with each other securely
       this token should be alpha numeric only
  EOF
  sensitive   = true
}

# Unfortunately, we have to repeat type definition here,
# see https://github.com/hashicorp/terraform/issues/30386
variable "workspace_sensitive_default_params" {
  type = object({
    vm = object({
      ci_user             = optional(string),
      ci_password         = optional(string),
      ci_ssh_pub_key_path = optional(string),
      system_timezone     = optional(string)
    }),
    metal_lb_ip_range  = optional(string),
    apiserver_endpoint = optional(string),
    k3s_token          = optional(string)
  })
}
