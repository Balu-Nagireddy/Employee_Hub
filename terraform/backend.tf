# -----------------------------------------------------------------------
# Terraform Backend Configuration (S3 + DynamoDB)
# -----------------------------------------------------------------------
#
# Bootstrapping Instructions:
#
#   1. Apply once with local state to create the backend resources:
#        terraform init
#        terraform apply -target=aws_s3_bucket.terraform_state \
#                        -target=aws_dynamodb_table.terraform_lock
#
#   2. Uncomment the backend block below and run:
#        terraform init -migrate-state
#
#   3. Confirm migration when prompted.
#
# The S3 bucket name includes your AWS account ID to ensure global uniqueness.
#
terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket       = "employee-hub-terraform-state-827949090758"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
    dynamodb_table = "employee-hub-terraform-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}
