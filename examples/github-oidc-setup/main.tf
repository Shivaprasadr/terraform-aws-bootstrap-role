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
      SetupType   = "github-oidc"
    }
  }
}

module "iam_bootstrap" {
  source = "../../modules/iam-bootstrap"

  aws_account_id = var.aws_account_id
  project_name   = var.project_name
  environment    = var.environment

  # GitHub OIDC Configuration - PRIMARY FOCUS
  github_org           = var.github_org
  github_repo          = var.github_repo
  github_branches      = var.github_branches
  enable_github_oidc   = true

  # Optional: Local development access (can be empty for GitHub-only setup)
  trusted_aws_principals = var.trusted_aws_principals

  # Policy Configuration
  terraform_custom_policy_json         = var.terraform_custom_policy_json
  terraform_deployment_role_policies   = var.terraform_deployment_role_policies

  # State bucket configuration
  create_state_bucket = var.create_state_bucket
  state_bucket_name   = var.state_bucket_name

  session_duration = var.session_duration

  tags = var.tags
}

# Output GitHub Actions workflow configuration
output "github_actions_workflow" {
  description = "Complete GitHub Actions workflow example"
  value = <<-EOT
    # Save this as .github/workflows/terraform.yml in your repository
    
    name: 'Terraform Deploy'
    
    on:
      push:
        branches: ${jsonencode(var.github_branches)}
      pull_request:
        branches: ${jsonencode(var.github_branches)}
    
    permissions:
      id-token: write   # Required for OIDC
      contents: read    # Required to checkout code
    
    jobs:
      terraform:
        name: 'Terraform'
        runs-on: ubuntu-latest
        
        steps:
        - name: Checkout
          uses: actions/checkout@v4
        
        - name: Configure AWS credentials
          uses: aws-actions/configure-aws-credentials@v4
          with:
            role-to-assume: ${module.iam_bootstrap.terraform_executor_role_arn}
            aws-region: ${var.aws_region}
            role-session-name: GitHubActions-Terraform
        
        - name: Setup Terraform
          uses: hashicorp/setup-terraform@v3
          with:
            terraform_version: 1.5.0
        
        - name: Terraform Init
          run: terraform init
        
        - name: Terraform Plan
          run: |
            # Assume the deployment role for actual Terraform operations
            export AWS_ROLE_ARN="${module.iam_bootstrap.terraform_deployment_role_arn}"
            terraform plan -no-color
        
        - name: Terraform Apply
          if: github.ref == 'refs/heads/main' && github.event_name == 'push'
          run: |
            # Assume the deployment role for actual Terraform operations
            export AWS_ROLE_ARN="${module.iam_bootstrap.terraform_deployment_role_arn}"
            terraform apply -auto-approve -no-color
  EOT
}

# Repository secrets that need to be configured
output "github_repository_secrets" {
  description = "GitHub repository secrets to configure"
  value = {
    AWS_ROLE_TO_ASSUME = module.iam_bootstrap.terraform_executor_role_arn
    AWS_REGION         = var.aws_region
    AWS_DEPLOYMENT_ROLE = module.iam_bootstrap.terraform_deployment_role_arn
  }
}

# Output role information
output "terraform_deployment_role_arn" {
  description = "ARN of the TerraformDeploymentRole"
  value       = module.iam_bootstrap.terraform_deployment_role_arn
}

output "terraform_executor_role_arn" {
  description = "ARN of the TerraformExecutorRole (for GitHub Actions)"
  value       = module.iam_bootstrap.terraform_executor_role_arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.iam_bootstrap.github_oidc_provider_arn
}

output "setup_complete" {
  description = "Setup completion message with next steps"
  value = <<-EOT
    🎉 GitHub OIDC Setup Complete!
    
    📋 Next Steps:
    1. Copy the GitHub Actions workflow above to .github/workflows/terraform.yml
    2. Add the following secrets to your GitHub repository:
       - AWS_ROLE_TO_ASSUME: ${module.iam_bootstrap.terraform_executor_role_arn}
       - AWS_REGION: ${var.aws_region}
    3. Commit and push to trigger the workflow
    
    🔐 Role Configuration:
    - GitHub can assume: ${module.iam_bootstrap.terraform_executor_role_arn}
    - Deployment role: ${module.iam_bootstrap.terraform_deployment_role_arn}
    - Allowed branches: ${join(", ", var.github_branches)}
    
    ✅ Your repository (${var.github_org}/${var.github_repo}) is now ready for secure Terraform deployments!
  EOT
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
