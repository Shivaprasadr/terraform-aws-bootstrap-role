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
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "iam_bootstrap" {
  source = "../../modules/iam-bootstrap"

  aws_account_id   = var.aws_account_id
  project_name     = var.project_name
  environment      = var.environment
  role_name_prefix = var.role_name_prefix

  # GitHub OIDC Configuration
  github_org           = var.github_org
  github_repo          = var.github_repo
  github_branches      = var.github_branches
  enable_github_oidc   = var.enable_github_oidc

  # Local development access
  trusted_aws_principals = var.trusted_aws_principals

  # Custom policy configuration
  custom_policy_json           = var.custom_policy_json
  deployment_role_policies     = var.deployment_role_policies

  # State bucket configuration
  create_state_bucket = var.create_state_bucket
  state_bucket_name   = var.state_bucket_name

  session_duration = var.session_duration

  tags = var.tags
}

# Output important information
output "setup_complete" {
  description = "Setup completion message"
  value = <<-EOT
    ✅ IAM Bootstrap Setup Complete!
    
    🔐 Roles Created:
    - DeploymentRole: ${module.iam_bootstrap.deployment_role_name}
    - ExecutorRole: ${module.iam_bootstrap.executor_role_name}
    
    🌐 GitHub Actions Role ARN: ${module.iam_bootstrap.executor_role_arn}
    
    💻 For local development, use:
    aws sts assume-role --role-arn ${module.iam_bootstrap.executor_role_arn} --role-session-name terraform-session
    
    📋 Next Steps:
    1. Add the ExecutorRole ARN to your GitHub repository secrets
    2. Configure your GitHub Actions workflow to use OIDC
    3. Use the provided AWS CLI commands for local development
  EOT
}

output "deployment_role_arn" {
  description = "ARN of the DeploymentRole"
  value       = module.iam_bootstrap.deployment_role_arn
}

output "executor_role_arn" {
  description = "ARN of the ExecutorRole"
  value       = module.iam_bootstrap.executor_role_arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.iam_bootstrap.github_oidc_provider_arn
}

output "github_actions_example" {
  description = "Example GitHub Actions workflow configuration"
  value       = module.iam_bootstrap.github_actions_example
}

output "local_aws_cli_example" {
  description = "Example AWS CLI commands for local development"
  value       = module.iam_bootstrap.local_aws_cli_example
}

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = module.iam_bootstrap.terraform_state_bucket_name
}

output "terraform_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.iam_bootstrap.terraform_dynamodb_table_name
}

output "backend_configuration" {
  description = "Backend configuration for using the created state bucket"
  value       = module.iam_bootstrap.backend_configuration
}

# Backward compatibility outputs
output "terraform_deployment_role_arn" {
  description = "ARN of the DeploymentRole (deprecated - use deployment_role_arn)"
  value       = module.iam_bootstrap.deployment_role_arn
}

output "terraform_executor_role_arn" {
  description = "ARN of the ExecutorRole (deprecated - use executor_role_arn)"
  value       = module.iam_bootstrap.executor_role_arn
}
