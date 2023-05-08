# AWS LocalStack, Integration with Terraform 
## Prerequisites
- Manjaro/Arch Linux (preferred)
- Docker (see
  https://github.com/Alliedium/awesome-linux-config/blob/master/manjaro/basic/install_docker.sh)
- Python3 + pip
```
sudo pacman -S python-pip --no-confirm
```
- Terraform 
```
sudo pacman -S terraform --no-confirm
```
- LocalStack
```
pip install localstack
```
- AWS CLI v2
```
sudo pacman -S aws-cli-v2 --no-confirm
```
- Clone this repo 
```
git clone https://github.com/Alliedium/awesome-terraform.git
cd ./03-aws-localstack
```

## Start LocalStack
All you need to do is to run
```
localstack start
```
from terminal (see https://docs.localstack.cloud/getting-started/installation/#starting-localstack-with-the-localstack-cli).

Please make sure that you keep the terminal window where you started
LocalStack opened since the moment you close it LocalStack shuts down.

Also, please note that by default LocalStack starts with ephemeral storage, meaning that,
once LocalStack instance is terminated, all state is 
discarded. Persistence can be enabled but only in a payed
LocalStack Pro version (see https://docs.localstack.cloud/references/persistence-mechanism/).

## Download and run LocalStack Cockpit
On Linux it runs as AppImage, see https://localstack.cloud/products/cockpit/

## Configure AWS CLI to use LocalStack
The easiest way to do it is to create AWS CLI profile called
`localstack` using `aws configure`:

```
aws configure --profile localstack
```
and enter the following:

```
AWS Access Key ID: local 
AWS Secret Access Key: local 
Default region name: us-east-1 
Default output format [None]: <Press Enter>
```
Then change your current AWS CLI profile to `localstack` via
```
export AWS_PROFILE=localstack
```
or (assuming you have AWS plugin for Oh-My-Zsh installed, see https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/aws/aws.plugin.zsh) via 
```
asp localstack
```

## Configure Terraform to use LocalStack
We are not going to use `tflocal` script that is supposed to lower the entry
barrier for beginners as it is not much more difficult to configure the
original `terraform` cli to work with LocalStack following
https://docs.localstack.cloud/user-guide/integrations/terraform/#manual-configuration

In our repository we've already done that, see `provider "aws" {` and
`terraform {` in `./main.tf`. You might be tempted to run `terraform
apply` at this stage but it is too early - if you do that you will get a
error because "Apply" should happen in two stages:
- (1) creation of S3 bucket for the state and DynamoDB table for the state
  lock (see https://developer.hashicorp.com/terraform/language/settings/backends/s3).
  At this stage we should not try to create any other resources.

- (2) creation of the main bulk of resources not used for 
  storing the state or the state lock. In our case this is just a single
  s3 bucket called "main-bucket".

Since the first stage requires us not to create any other resources
apart from the ones required for storing the state or its lock we need
to modify `main.tf` temporarily by commenting the blocks that start with
```
resource "aws_s3_bucket" "main-bucket" {
```
and 
```
terraform {
  backend "s3" {
```

Before we apply our modified Terraform configuration let us start
monitoring of AWS resources via AWS CLI v2. To be able to do let us
add the following lines
```
alias awsl='aws --endpoint-url=http://localhost:4566 '
alias watch='watch '
```
to `~/.zshrc` (`~/.bashrc`) and run `source ~/.zshrc` (`source
~/.bashrc`). These lines create aliases for `watch` and `aws` commands
so that we can write `watch awsl ...` and monitor 
- list of AWS S3 buckets via `watch awsl s3 ls`
- content of `s3://tf-state` bucket via `watch awsl s3 ls s3://tf-state
  --recursive`
- list of DynamoDB tables via `watch awsl dynamodb list-tables`.
It would make sense to run each of these commands in separate tiles of
the terminal so that we can monitor all the resources in parallel.

Please note that it is necessary to switch your AWS CLI profile to
`localstack` (the one we created above) so that AWS CLI knows that it
should connect to LocalStack. Just specifying `--entrypoint` might not
be enough for some AWS CLI subcommands (such as `dynamodb`), while
others (like `s3`) might work even when profile is not switched to
`localstack`. 

Now, once monitoring is started (and assuming LocalStack is started)
we can run the following commands:
```
terraform init
terraform apply
```
and make sure that `tf-state` S3 bucket and `terraform-lock` table are
created. At this stage `tf-state` bucket remains empty. 

## Moving Terraform state to AWS S3

Now let specify AWS S3 as a backend for Terraform state by uncommenting
the block that starts with
```
terraform {
  backend "s3" {
```
and running `init` again:
```
terraform init
```
Please note that running `terraform init` is absolutely necessary as
this is how Terraform "enables" our new backend.

Terraform will ask us if it is ok to move the state to S3, we should say
`yes` and as a result we'll see that `tf-state` bucket now contains
`terraform.tfstate` file. The local file `terraform.tfstate` is no
longer needed and we can safely remove it
```
rm ./terraform.tfstate
```
Since `s3://tf-state` bucket we create have versions enabled it should
be possible to watch all versions of the state via 
```
awsl s3api list-object-versions --bucket tf-state
```
## Create the main set of resources
via uncommenting the block the starts with
```
terraform {
  backend "s3" {
```
and running
```
terraform apply
```
After that we should see one more S3 bucket named `main-bucket`.

## Other modules and their state
You might have noticed that we have two subfolders `app` and `db` that
contain additional resources for two different components of some imaginary
application for which we want to provision infrastructure. Terraform configurations
in those folders, however, were ignored when we applied configuration
on the main level. That is because Terraform treats each folder as a
separate module with an isolated set of resources that are supposed to
be managed separately (see
https://developer.hashicorp.com/terraform/language/files#directories-and-modules).
As a result, we face the following problems:
- we are forced to copy-paste configurations of both AWS
provider and S3 backend across all the modules which is not very
convenient;
- configuration of S3 backend needs to be slightly
different for each module so that they do not override states of each
other; this increases a chance of human error;
- we cannot parameterize content of `backend` block using 
variables (it is a known limitation of how backends work in Terraform - see
https://developer.hashicorp.com/terraform/language/settings/backends/configuration).
design;
- `terraform apply` ignores configurations in other modules which is not
  always convenient as sometimes it might be necessary to apply
  everything with a single command. Same is true for `terraform init`.

All these problems are fully or partially solved by the tool called
"Terragrunt" (see
https://terragrunt.gruntwork.io/docs/getting-started/quick-start/#introduction).
Our next example will be based on using Terragrunt to refactor our
current example and apply DRY principle.

## Applying configurations of "app" and "db" modules
Let us run `init` and `apply` in both `app` and `db` subfolders:

```
cd ./app
terraform init
terraform apply
cd ../db
terraform init
terraform apply
```

After these commands our terminal-based monitoring (that one we started
above via `watch`) should show us
- three AWS S3 buckets
  - `terraform.tfstate`
  - `app/terraform.tfstate`
  - `db/terraform.tfstate`
- single DynamoDB table `terraform-lock`

The reason we have a single table for all the modules is because we can
store locks for different modules inside the same table. This can be
checked via
```
awsl dynamodb scan --table-name terraform-lock
```
command.



## References
### Modules
- https://developer.hashicorp.com/terraform/language/files#directories-and-modules

### LocalStack
- https://github.com/localstack/localstack
- https://localstack.cloud/features/
- https://docs.localstack.cloud/references/
- https://docs.localstack.cloud/user-guide/aws/feature-coverage/
- https://docs.localstack.cloud/user-guide/integrations/terraform/
- https://docs.localstack.cloud/getting-started/installation/#localstack-cli
- https://localstack.cloud/products/cockpit/
- https://docs.localstack.cloud/references/persistence-mechanism/

### S3 backend
- https://developer.hashicorp.com/terraform/language/settings/backends/configuration
- https://developer.hashicorp.com/terraform/language/settings/backends/s3
- https://angelo-malatacca83.medium.com/aws-terraform-s3-and-dynamodb-backend-3b28431a76c1

### AWS S3
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
- https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/list-object-versions.html

### AWS DynamoDB
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
- https://hub.docker.com/r/amazon/dynamodb-local/
- https://github.com/awslabs/dynamodb-shell

### Terragrunt
- https://github.com/gruntwork-io/terragrunt
- https://terragrunt.gruntwork.io/docs/getting-started/quick-start/#introduction
- https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/

### OhMyZsh
https://github.com/ohmyzsh/ohmyzsh/
https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/aws/aws.plugin.zsh
