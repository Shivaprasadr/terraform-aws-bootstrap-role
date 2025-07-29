# Simple IAM Role Setup without GitHub OIDC
# This example creates basic IAM roles for Terraform deployments without GitHub integration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create the bootstrap roles without GitHub OIDC
module "iam_bootstrap" {
  source = "../../modules/iam-bootstrap"

  # Basic configuration
  aws_account_id     = var.aws_account_id
  project_name       = var.project_name
  environment        = var.environment
  role_name_prefix   = var.role_name_prefix

  # Disable GitHub OIDC integration
  enable_github_oidc = false
  github_org         = ""
  github_repo        = ""

  # Allow specific AWS principals to assume the executor role
  trusted_aws_principals = var.trusted_aws_principals

  # Optional: Add custom policies for the deployment role
  deployment_role_policies = var.deployment_role_policies

  # Optional: Use custom policy instead of AdministratorAccess
  custom_policy_json = var.custom_policy_json

  # S3 State backend configuration
  create_state_bucket = var.create_state_bucket
  state_bucket_name   = var.state_bucket_name

  # Session duration
  session_duration = var.session_duration

  # Tags
  tags = var.tags
}
