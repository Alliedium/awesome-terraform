# Proxmox VM provisioning via Terraform

## Prerequisites
### Proxmox cluser
With at least two nodes

###  Clone git repository 
via
```
git clone https://github.com/Alliedium/awesome-terraform.git` 
cd ./awesome-terraform
```
### Install terraform
on Manjaro/ArchLinux via

```
sudo pacman -S terraform
terraform version
```

### Install GraphViz
Graphviz is open source graph visualization software (see https://graphviz.org/) which we will require for rendering Terraform configuration graphs.
On Manjaro/ArchLinux it can be installed via
```
sudo pacman -S graphviz
```

### Creating VM templates via `vm-cloud-init-shell` scripts
Telmate Proxmox provider for Terraform 
(https://github.com/Telmate/terraform-provider-proxmox) which we'll use
below has a limitations:
- Creating a VM based on template located on a different node is not supported. 
  template). See https://github.com/Telmate/terraform-provider-proxmox/issues/536#issuecomment-1144705404
- Requires QEMU Guest Agent pre-installed inside the templates if
  `oncreate` parameter is set to `true`. Please note that `oncreate` will be replace with `vm_state` attribute 
  in the next version (see https://github.com/Telmate/terraform-provider-proxmox/pull/725).
- Rough around the edges (many bugs and lots of inconsistent behavior). 

The first limitation requires us to create a separate template (or just
a VM which can be used as a template) on each target node of Proxmox.
For that task we will use shell scripts from
```
https://github.com/Alliedium/awesome-proxmox/tree/main/vm-cloud-init-shell`
```
repo.

Make sure to use 
```
Pz_VM_NAME_PREFIX=vm-4-tf-
N_VMS=2
Pz_DISK_FORMAT='qcow2'
```
in `.env` file for the scripts (see https://github.com/Alliedium/awesome-proxmox/tree/main/vm-cloud-init-shell#4-export-variables-from-your-configuration).
As a result you are expected to have VMs `vm-4-tf-1` and `vm-4-tf-2`
located on each of the target nodes of Proxmox cluster.

The rest of the parameters are not very important as long as you specify
the same parameters inside Terraform variable values file `my.tfvars`
(see below).



## Introduction to Terraform

Terraform terminology:

- *Infrastructure as Code (IaC)*: The practice of managing and
  provisioning infrastructure through code.
- *Provider*: A plugin that allows Terraform to interact with a specific
  cloud or service provider, such as AWS or Azure.
- *Resource*: A component of your infrastructure that can be managed by
  Terraform. Examples of resources include virtual machines, databases,
  and network interfaces.
- *State*: The state of your infrastructure, which is stored in a file
  called the "state file". This file contains information about the
  resources that Terraform is managing, their current state, and their
  dependencies.
- *Configuration*: A set of files written in a human-readable syntax that
  resembles JSON or HCL (HashiCorp Configuration Language), and are used
  to specify the desired state of the infrastructure. Once you have
  defined your infrastructure as code in Terraform configuration files,
  you can use the Terraform CLI to plan, apply, and manage changes to
  your infrastructure.
- *Plan*: A preview of the changes that Terraform will make to your
  infrastructure. You can review and approve the plan before applying
  the changes.
- *Apply*: The process of making changes to your infrastructure based on
  the Terraform plan.
- *Module*: A reusable component of your infrastructure that can be shared
  across different Terraform configurations. Modules can be used to
  create abstractions, simplify complex configurations, and promote
  consistency across environments.
- *Output*: The result of a Terraform configuration. Outputs can be used
  to display information about the resources that Terraform has created,
  such as IP addresses or DNS names.
- *Variable*: A value that can be passed to a Terraform configuration.
  Variables can be used to customize your infrastructure, such as
  specifying the number of instances to create or the size of a storage
  volume.

## Initialize terraform
via 
```
terraform init
```
is the first command you need to run when working with a new or existing
Terraform configuration. This command initializes various settings and
downloads the required plugins and modules needed for your
configuration. When you run terraform init, Terraform will perform the
following tasks:

- Initialize a new or existing Terraform working directory: Terraform
  will create a .terraform directory in the working directory, which
  will contain the state file, as well as other files and directories
  required for the configuration.
- Download required provider plugins: If the configuration specifies any
  providers that are not yet installed, terraform init will download the
  necessary provider plugins and install them in the appropriate
  directory.
- Download required modules: If the configuration uses any modules,
  terraform init will download the necessary module code and install it
  in the appropriate directory.
- Initialize the backend: If the configuration uses a remote backend,
  terraform init will initialize the backend and set up any necessary
  authentication or connection details.
- Overall, terraform init is an essential command that ensures that your
  Terraform configuration is set up correctly and ready to be used.


## Configuring Proxmox Terraform Provider

Follow instructions from https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md
and create a user and a token associated with that user.
See
https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/index.md#creating-the-connection-via-username-and-api-token).
and
https://pve.proxmox.com/wiki/User_Management
for more information.

You might need to deviate from the instructions above in the following
aspects:

- Use the following privileges for `TerraformProv` role:
```
Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt Pool.Audit
```
- Make sure that `Privilege Separation` on `Permissions->API Tokens`
  Proxmox GUI tab is set to `No`

Once you have the token you need to setup the environment variables
containing the token:

```
export PM_API_TOKEN_SECRET='YOUR_TOKEN_SECRET'
export PM_API_TOKEN_ID='YOUR_TOKEN_ID'
```

And the environment variable containing your Proxmox API URL:
```
export TF_VAR_pve_api_url=https://YOUR_PROXMOX_NODE_IP:8006/api2/json
```
The latter will be used by Terraform configuration. 

## Define your variables
Copy the example file
```
cp ./example.tfvar ./my.tfvars
```
and then edit `my.tfvars` to match your case. Make sure to use the same
variables as the ones you specified in `.env` file for
"vm-cloud-init-shell" scripts (see [[Prerequisites]] section). 

## Study the main configuration file
The file `main.tf` is a required file in a Terraform project that
defines the resources that will be created or managed by Terraform. This
file contains the main Terraform code for your project and is typically
used to define the infrastructure resources you need to provision, such
as virtual machines, storage accounts, or network interfaces.

In `main.tf`, you will define the resources using the Terraform syntax,
which consists of '`resource` blocks, `provider` blocks, and variables
(`variable` blocks).

- Resource blocks define the resources that you want to create or
  manage, and they specify the properties and attributes of those
  resources. 
- Provider blocks are used to configure the provider that you will use
  to manage the resources, such as AWS, Azure, or Google Cloud Platform. 
- Variables are used to parameterize your Terraform configuration so
  that you can customize it for different environments or situations.

  `main.tf` is a crucial file in your Terraform project, as it defines
  the core infrastructure resources that you will be managing with
  Terraform. It is typically the file that you will spend most of your
  time editing and updating as your infrastructure needs change over
  time.

  There are also `terraform` and `locals` blocks:

- The `terraform` block is used to configure the behavior of Terraform
  itself, rather than defining resources to manage. It can be used to
  set backend configuration, such as where to store the state file, as
  well as configure the provider installation behavior and the version
  of Terraform to use.

- The `locals` block is used to define local values that can be used
  within your Terraform code. These values are not stored in the state
  file or passed to the provider, but can be used to simplify complex
  expressions, make your code more readable, and reduce duplication. For
  example, you might define a local variable to hold the IP address
  range for your network so that you can use it in multiple places
  within your code.

## Show the configuration graph
Terraform can scan the configuration (even before it is applied) and 
generate the structure of the configuration as a graph in DOT language - see
https://graphviz.org/doc/info/lang.html for more information:
```
terraform graph > my-config-graph.dot
```
Now we can render this graph using GraphViz (see [[Prerequisites]]):
```
dot -Tpdf my-config-graph.dot > my-config-graph.pdf
```
which would produce PDF file with the graph rendered using vector
graphics.

## Study the variable files

In Terraform, `variables.tf` is used to define the input variables that
your modules and configurations will use, while `terraform.tfvars` is used
to set the values for those variables.

The order of precedence for variable values in Terraform is:

- Command-line flags: You can set variable values using `-var` or `-var-file`
flags when running the terraform apply or terraform plan commands. These
values take the highest precedence.

In our case `my.tfvars` file provides the values for variables defined
in `variables.tf` and is passed via `-var-file` flag.

- Environment variables: You can set variable values using environment
variables, such as `TF_VAR_name`. These values take precedence over values
set in `terraform.tfvars`, but not over values set using command-line
flags. In our case we export `TF_VAR_pve_api_url` environment variable
to define value of `pve_api_url` Terraform variable. 

- `terraform.tfvars` or `terraform.<workspace>.tfvars` files in the current
working directory. Values set in these files take precedence over values
set in `variables.tf`, but are overridden by values set using command-line
flags or environment variables.

- `terraform.tfvars.json` files: If a `terraform.tfvars.json` file is present
in the current working directory, it will also be automatically loaded.
Like `terraform.tfvars`, values set in this file take precedence over
values set in `variables.tf`, but are overridden by values set using
command-line flags or environment variables.

- `variables.tf` files: The default values defined in `variables.tf` are used
if no other values are specified. In our case we define default values
for some of the variables (`cores` or `cpu`).

In summary, the order of precedence for variable values in Terraform is
- command-line flags
- environment variables
- `terraform.tfvars` files,
- `terraform.tfvars.json` files
- `variables.tf` files. 

When setting variable values, it's important to keep this order of precedence
in mind to avoid unexpected behavior.


## Generate execution plan
via
`terraform plan -var-file my.tfvars` 
which is a Terraform command that shows a preview of the changes that
Terraform will make when terraform apply is run. When you run `terraform
plan`, Terraform analyzes your current infrastructure configuration (as
specified in the configuration files) and compares it to the current
state of the infrastructure (as stored in the state file). It then
creates an execution plan that shows the changes that Terraform will
make to the infrastructure to bring it in line with the desired
configuration.

The execution plan includes information about what resources Terraform
will create, update, or delete, and any changes to resource attributes
such as instance type or IP address. The plan also shows any changes to
dependencies between resources.

`terraform plan` is a safe way to preview changes to your infrastructure
before they are actually made. It allows you to review the changes and
ensure that they are what you intended, and can help prevent unintended
changes or errors. See
https://developer.hashicorp.com/terraform/cli/commands/plan for more
information.

We can also optionally save the plan to a file via

```
terraform plan -var-file my.tfvars -out my.plan`
```

## Show the current plan

The stored plan can be shown via
```
terraform show ./my.plan
```

Please note that running just 
```
terraform show
```
displays the current state, not the plan. Since at this state we are not
supposed to how any state (just yet) `terraform show` will output just
`No state`.


## Apply the changes
either via
```
terraform apply my.plan # uses the previously saved plan
```
or via

```
terraform apply -var-file ./my.tfvars # re-generates the plan and applies it
```

`terraform apply` is a Terraform command used to apply the changes to
the infrastructure. It reads the Terraform configuration files, creates
a detailed execution plan, and applies the changes to reach the desired
state.

When you run `terraform apply`, it checks the current state of the
infrastructure with the state file and creates a new plan for any
necessary changes. It then prompts the user to confirm the execution
plan before proceeding with the changes. Once you confirm, Terraform
applies the changes and updates the state file to reflect the new state
of the infrastructure.

`terraform apply` also supports various options and flags to modify its
behavior, such as `-auto-approve` to automatically apply changes without
prompting for confirmation, and target to apply changes to specific
resources. See
https://developer.hashicorp.com/terraform/cli/commands/apply for more
information.

Once the changes are applied you can check that VMs are created 
via Proxmox Web UI. Please note that our Terraform configuration
automatically launches VMs (thanks to `oncreate = true` flag in
`main.tf`).

## Show the current state

Once the changes are applied Terraform stores its state in
`terraform.tfstate` file. The current state can be shown via
```
terraform show
```

or 

```
terraform show ./terraform.tfstate
```

It is also possible to list all the resources in the current state via
```
terraform state list
```
or 
```
terraform state list ./terraform.tfstate
```
Finally, it is also possible to show a particular resource in the
current state. For example, to show the state of the first VM run

```
terraform state show 'proxmox_vm_qemu.light_vm["vm-tf-clone-1"]'
```

## Destroy the created resources 
via
```
proxmox destroy -var-file ./my.tfvars
```
which is a Terraform command that destroys the infrastructure resources
that were created using the Terraform configuration files. It deletes
all resources that were created and managed by Terraform in the order
they were created, based on the current Terraform state. It is important
to note that running terraform destroy will delete resources, which can
result in data loss, so it should be used with caution. Before running
terraform destroy, it's recommended to review the resources that will be
destroyed by running terraform plan. Please see https://developer.hashicorp.com/terraform/cli/commands/destroy
for more information.

Deletion of all the VMs can be confirmed by checking via Proxmox Web UI.

Please note that
```
proxmox apply -destroy -var-file ./my.tfvars
```
would have the same effect as the command above.

## Running a few experiments
`main.tf` file contains a few commented blocks that are there for you to
uncomment and see how this impacts the way Terraform works.

### Experiment #1
Uncomment the block with the third VM (marked with `EXPERIMENT BLOCK 1`),
apply the changes and make sure that it just creates one more VM. Then 
delete resources via `terraform delete`.

### Experiment #2
Revert the changes made in the previous experiment. 
Then replace `vm.name => vm` in `for_each` with the commented content of
`EXPERIMENT BLOCK 2`. Then observe the change in the way terraform
tracks resources (by their ids). Once 2 VMs are created uncomment the
blocks for the third VM (`EXPERIMENT BLOCK 1`) and try to apply the
changes. You'll see that instead of creating one more VM Terraform tries
to both change 1 VM and create one more VM. This is different from how
Terraform behaved in Experiment #1 above, right? Please try to explain
the difference in behavior (hint - it has to do with the new way to
tracking resources).

### Experiment #3
Revert the changes made in the previous experiments. Then change the
disk size for VMs in `my.tfvars` and run `terraform apply -var-file
./my.tfvars`. The disk of both VMs (including the file system on the
disks) should get extended automatically.

### Experiment #4
Revert the changes made in the previous experiments and then change the
IP address prefix for VMs in `my.tfvars`. Running 
`terraform apply -var-file ./my.tfvars` should get IP addresses of VMs
changed.


## Study `.gitignore`
to make sure you understand what resources should to be under source
control and what should not.


## References

- https://github.com/Telmate/terraform-provider-proxmox
- https://pve.proxmox.com/wiki/User_Management
- https://github.com/Telmate/terraform-provider-proxmox/issues/687#issuecomment-1479322276
- https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180#a9b0
- https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
- https://upcloud.com/resources/tutorials/terraform-variables
- https://developer.hashicorp.com/terraform/cli/commands/plan
- https://developer.hashicorp.com/terraform/cli/commands/apply
- https://developer.hashicorp.com/terraform/cli/commands/destroy
- https://github.com/Alliedium/awesome-proxmox
- https://graphviz.org/doc/info/lang.html
