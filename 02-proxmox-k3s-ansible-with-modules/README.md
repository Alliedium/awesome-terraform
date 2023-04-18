## Prerequisites
This example assumes you
- cloned this repository with git submodules:
```
git clone https://github.com/Alliedium/awesome-terraform.git
git submodule init
git submodule update
cd ./02-proxmox-k3s-ansible-with-modules
```
- followed all the steps from https://github.com/Alliedium/awesome-terraform/tree/main/01-proxmox-vm-provisioning-basics#prerequisites
including creating base VMs `base-vm-tf-1`, `base-vm-tf-2` and
`base-vm-tf-3` using scripts from https://github.com/Alliedium/awesome-proxmox/tree/main/vm-cloud-init-shell
with

```
Pz_VM_NAME_PREFIX=base-vm-tf-
N_VMS=3
```
- defined Terraform variable values via running
```
cp ./variables.tfvars.example ./my.tfvars
```
and changed values in `my.tfvars` including Proxmox API token id
`pm_api_token_id` and secret `pm_api_token_secret` to match your case
and environment.

- Install `ipcalc` via 
```
sudo pacman -S ipcalc --no-confirm
```
and `terraform-repl` and `tfrepl` from https://github.com/paololazzari/terraform-repl
and https://github.com/andreineculau/tfrepl

## A quick walk-though the architecture of the configuration
### k3s-ansible Ansible playbook
(https://github.com/techno-tim/k3s-ansible)
is an Ansible playbook for installing k3s cluster on already provisioned
VMs. The playbook is attached to the **awesome-terraform** Git repository
as a Git submodule and is integrated with Terraform configuration via 
templates (see below).

### Templates 
are in `./templates` and are used for generating Ansible inventory and
group variables for k3s-ansible Ansible playbook (see
https://github.com/techno-tim/k3s-ansible).

### Modules
are located in `./modules`,
- `light_vm` is a wrapper around `proxmox_qemu_vm` which provides a
  simplified API for VM creation,
- `k8s_agent_node` and `k8s_master_node` are thin wrappers around
  `light_vm` and implemented for educational purposes. In general it is
  not recommended to implement think wrappers around Terraform,
  resources (see https://developer.hashicorp.com/terraform/language/modules/develop#when-to-write-a-module)
- `wparam-remove-nulls` is an utility module that is used as a function
  designed to remove null-valued fields from an object.

### Variables
are defined in `variables.tf` and are broken in two groups - sensitive
and non-sensitive. Both groups are represented by a pair of objects. The
first object in a pair (`workspace_params` for instance) contains
settings for specific workspace while the second element of the pair
contains default settings. All fields are optional so if some field is
not defined for a workspace then a default value for that field is used
(if present). We use `deepmerge` (see https://github.com/Invicton-Labs/terraform-null-deepmerge)
to implement that. `deepmerge` doesn't treat null as a missing value and
that is why we create a separate module `./modules/wparam-remove-nulls`

### Expressions and functions
are used extensively to calculate IP addresses for VMs based on a number
of provisioned vms (`n_vms` parameter) and start IP (IP of the first
VM). 
#### Exercise 1
- Study the algorithm of VM IP addresses calculation in `main.tf` and 
way `cidrsubnet` function is used. Make sure to use `ipcalc` utility to
get a better understanding of the algorithm.
- Reproduce all the steps of the algorithm in Terraform console
  `terraform console` and its enhanced versions: `terraform-repl` and `tfrepl`.

### Sensitive variables and outputs
Pay attention to sensitive information now being shown in outputs because
it is a derivative of sensitive variables defined in `variables.tf`.

## (Optional) Create a new workspace
```
terraform workspace new production
```

## Generate SSH keys for VMs
```
ssh-keygen -f ~/.ssh/id_pve_tf_k3s_ed25519 -t ed25519 -N ''
chmod 400 ~/.ssh/id_pve_tf_k3s_ed25519
```
and make sure that `vm.ci_ssh_pub_key_path` in `my.tfvars` points to your
public key `vm.ci_ssh_pub_key_path.pub`. Please note that Terraform
configuration assumes that private SSH key is located next to public SSH
key and is named similarly (just without `.pub` extension).

## VM provisioning for k3s cluster
Apply Terraform configuration via 
```
terraform apply -var-file ./my.tfvars
```
- provisions VMs for K3s (Kubernetes nodes) based on base VMs 
- generates Ansible inventory and group variables in
  `./external/k3s-ansible/inventory/terraform` based on templates in
  `./templates` folder. 

You can also re-generate only Ansible inventory for k3s via
```
terraform apply -var-file ./my.tfvars -replace=local_file.k3s_ansible_inventory_file -refresh=false
```

## Installing Kubernetes cluster on the VMs
Ansible playbook from https://github.com/techno-tim/k3s-ansible project
doesn't wait till completion of cloud-init inside the provisioned VMs so
you need to wait a bit (1 minute should be enough) before running the
following command:
```
ansible-playbook ./external/k3s-ansible/site.yml -i ./external/k3s-ansible/inventory/terraform
```
Once k3s cluster is created you can extract `kubeconfig` from one of the
nodes
```
scp -i ~/.ssh/id_pve_tf_k3s_ed25519 your-user@your-ip:~/.kube/config ./k3s-tf.kubeconfig
```
(please make sure to replace username, ip and path to private ssh key
specific to your case).

Finally, make sure that you can access Kubernetes:
```
kubectl get pods --kubeconfig ./k3s-tf.kubeconfig -A
```

## What can be improved
We could
- Get rid of `./modules/k8s_agent_node` and
  `./modules/k8s_master_node` and use `./modules/light_vm` module
  directly. This is because writing thin wrappers for modules in
  anti-pattern, see https://developer.hashicorp.com/terraform/language/modules/develop#when-to-write-a-module
  The reason those two modules were added to this example in the first
  place is to demonstrate how local modules can reference each other.
- Create VM templates via https://github.com/pvelati/ansible-role-proxmox-kvm-mgmt
instead of using https://github.com/Alliedium/awesome-proxmox/tree/main/vm-cloud-init-shell
- Extract kubeconfig  via https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file
or via Ansible
- Wrap k3s-ansible Ansible playbook with our own Ansible playbook that
  automatically waits for cloud-init to finish.
- Call k3s-ansible Ansible playbook automatically via `local-exec`, see https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
and https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- `k3s_token` can be generated automatically by Terraform - see https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
- Ignore some of the parameteres via Terraform Lifecycles, see https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
- Terraform state can we stored in a remote backend (S3 for instance),
  see https://developer.hashicorp.com/terraform/language/settings/backends/configuration
- We could check that we can connect to the k3s cluster via the wrapper
  Ansible playbook

## References

### Terraform console alternatives
- https://github.com/paololazzari/terraform-repl
- https://github.com/andreineculau/tfrepl

### Terraform overview
- https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180#a9b0
- https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
- https://github.com/hashicorp/terraform/issues/516
- https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1

### Terraform and Ansible integration 
- https://www.digitalocean.com/community/tutorials/how-to-use-ansible-with-terraform-for-configuration-management
- https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
- https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec
- https://github.com/techno-tim/k3s-ansible
- https://developer.hashicorp.com/terraform/language/expressions/strings#string-templates
- https://developer.hashicorp.com/terraform/language/functions/templatefile
- https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
- https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables

### Deepmerge
- https://github.com/Invicton-Labs/terraform-null-deepmerge
- https://github.com/Kalepa/terraform-null-deepmerge
- https://github.com/cloudposse/terraform-provider-utils
- https://github.com/hashicorp/terraform/issues/24987
- https://github.com/hashicorp/terraform/issues/22316
- https://github.com/cloudposse/terraform-provider-utils/issues/11

### Proxmox provider
- https://github.com/Telmate/terraform-provider-proxmox
- https://pve.proxmox.com/pve-docs/qm.1.html

### Similar implementations
- https://lachlanlife.net/posts/2022-09-provisioning-vms/
- https://github.com/NatiSayada/k3s-proxmox-terraform-ansible
- https://github.com/adamkoro/k3s-terraform-ansible
- https://github.com/arashkaffamanesh/ansible-k3s
- https://github.com/waiyanwh/k3s-terraform-proxmox-ansible
- https://github.com/fvumbaca/terraform-proxmox-k3s
- https://github.com/sei-noconnor/k3s-production
- https://github.com/eplightning/hetzner-k3s-tf-ansible
- https://github.com/onedr0p/flux-cluster-template
- https://github.com/developer-guy/kubernetes-cluster-setup-using-terraform-and-k3s-on-digitalocean

### Terraform Advanced topics
- https://developer.hashicorp.com/terraform/language/modules/develop#when-to-write-a-module
- https://stackoverflow.com/questions/72183481/how-to-describe-an-object-type-variable-in-terraform
- https://developer.hashicorp.com/terraform/language/expressions/strings#heredoc-strings
- https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
- https://developer.hashicorp.com/terraform/language/settings/backends/configuration
- https://developer.hashicorp.com/terraform/language/data-sources
