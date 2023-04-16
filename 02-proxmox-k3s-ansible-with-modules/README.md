## Prerequisites
This example assumed you
- followed all the steps from https://github.com/Alliedium/awesome-terraform/tree/main/01-proxmox-vm-provisioning-basics#prerequisites
including creating base VMs `base-vm-tf-1`, `base-vm-tf-2` and
`base-vm-tf-3` using scripts from https://github.com/Alliedium/awesome-proxmox/tree/main/vm-cloud-init-shell
with

```
Pz_VM_NAME_PREFIX=base-vm-tf-
N_VMS=3
```
- installed `terraform-repl` from https://github.com/paololazzari/terraform-repl
 and `tfrepl` from https://github.com/andreineculau/tfrepl
- defined Terraform variable values via running
```
cp ./variables.tfvars.example ./variables.tfvars
cp ./variables-k3s.tfvars.example ./variables-k3s.tfvars
```
and then changing values in `variables.tfvars` and
`variables-k3s.tfvars` to match your case.

## VM provisioning for k3s cluster
```
terraform apply -var-file ./variables.tfvars
```

You can also re-generate Ansible inventory via
```
terraform apply -var-file ./my.tfvars -replace=local_file.k3s_ansible_inventory_file -refresh=false
```

## Installing Kubernetes cluster on the VMs
```
ansible-playbook ./external/k3s-ansible/site.yml -i ./external/k3s-ansible/inventory/terraform
```
and after that copy your kubeconfig locally via
```
scp -i ~/.ssh/id_tf_ed25519 ciansible@10.109.1.20:~/.kube/config ./k3s-tf.kubeconfig
```
(please make sure to replace username, ip and path to private ssh key
specific to your case).

Finally, make sure that you can access Kubernetes:
```
kubectl get pods --kubeconfig ./k3s-tf.kubeconfig -A
```


## References
- https://developer.hashicorp.com/terraform/language/expressions/strings#string-templates
- https://developer.hashicorp.com/terraform/language/functions/templatefile
- https://developer.hashicorp.com/terraform/language/data-sources
- https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
- https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
- https://github.com/paololazzari/terraform-repl
- https://github.com/andreineculau/tfrepl
