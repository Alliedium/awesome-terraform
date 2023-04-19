provider "aws" {
  access_key                  = "local"
  secret_key                  = "local"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb       = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
  }
}

terraform {
  backend "s3" {
    bucket                      = "tf-state"
    key                         = "app/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://s3.localhost.localstack.cloud:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
    dynamodb_table              = "terraform-lock"
    dynamodb_endpoint           = "http://localhost:4566"
    encrypt                     = true
  }
}


resource "aws_s3_bucket" "app_bucket" {
  bucket = "app-bucket"
}

