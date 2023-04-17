# AWS LocalStack, Integration with Terraform 
## Prerequisites
- Manjaro/Arch Linux (preferred)
- Python3 + pip
- Terraform 
```
sudo pacman -S terraform --no-confirm
```
- LocalStack
```
pip install localstack
```
- tflocal script
```
pip install terraform-local
```
- AWS CLI v2
```
sudo pacman -S aws-cli-v2 --no-confirm
```

## Start LocalStack
Follow https://docs.localstack.cloud/getting-started/installation/#starting-localstack-with-the-localstack-cli

## Download and run LocalStack Cockpit
On Linux it runs as AppImage, see https://localstack.cloud/products/cockpit/

## Use tflocal script to create S3 bucket in LocalStack via Terraform
Follow the steps from
https://docs.localstack.cloud/user-guide/integrations/terraform/

## Check that S3 is created
using the following methods
- AWS CLI v2
```
aws --endpoint-url=http://localhost:4566 s3 ls
```
- LocalStack logs in terminal
- LocalStack logs in Cockpit 

## Configure Terraform to use LocalStack (instead of tflocal)
See https://docs.localstack.cloud/user-guide/integrations/terraform/#manual-configuration

## References
- https://github.com/localstack/localstack
- https://localstack.cloud/features/
- https://docs.localstack.cloud/references/
- https://docs.localstack.cloud/user-guide/aws/feature-coverage/
- https://docs.localstack.cloud/user-guide/integrations/terraform/
- https://docs.localstack.cloud/getting-started/installation/#localstack-cli
- https://localstack.cloud/products/cockpit/
