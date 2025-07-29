output "deployment_role_arn" {
  description = "ARN of the DeploymentRole"
  value       = aws_iam_role.deployment_role.arn
}

output "deployment_role_name" {
  description = "Name of the DeploymentRole"
  value       = aws_iam_role.deployment_role.name
}

output "executor_role_arn" {
  description = "ARN of the ExecutorRole"
  value       = aws_iam_role.executor_role.arn
}

output "executor_role_name" {
  description = "Name of the ExecutorRole"
  value       = aws_iam_role.executor_role.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (if created)"
  value       = local.github_oidc_enabled ? aws_iam_openid_connect_provider.github[0].arn : null
}

output "aws_account_id" {
  description = "AWS Account ID where the roles were created"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region where the roles were created"
  value       = data.aws_region.current.name
}

output "github_actions_example" {
  description = "Example GitHub Actions workflow configuration"
  value = local.github_oidc_enabled ? {
    role_to_assume = aws_iam_role.executor_role.arn
    aws_region     = data.aws_region.current.name
    deployment_role = aws_iam_role.deployment_role.arn
  } : null
}

output "local_aws_cli_example" {
  description = "Example AWS CLI commands for local development"
  value = {
    assume_executor_role = "aws sts assume-role --role-arn ${aws_iam_role.executor_role.arn} --role-session-name terraform-session"
    assume_deployment_role = "aws sts assume-role --role-arn ${aws_iam_role.deployment_role.arn} --role-session-name terraform-deployment"
  }
}

# Backward compatibility outputs (deprecated - use deployment_role_* and executor_role_* instead)
output "terraform_deployment_role_arn" {
  description = "ARN of the DeploymentRole (deprecated - use deployment_role_arn)"
  value       = aws_iam_role.deployment_role.arn
}

output "terraform_deployment_role_name" {
  description = "Name of the DeploymentRole (deprecated - use deployment_role_name)"
  value       = aws_iam_role.deployment_role.name
}

output "terraform_executor_role_arn" {
  description = "ARN of the ExecutorRole (deprecated - use executor_role_arn)"
  value       = aws_iam_role.executor_role.arn
}

output "terraform_executor_role_name" {
  description = "Name of the ExecutorRole (deprecated - use executor_role_name)"
  value       = aws_iam_role.executor_role.name
}

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = var.create_state_bucket ? aws_s3_bucket.terraform_state[0].id : null
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = var.create_state_bucket ? aws_s3_bucket.terraform_state[0].arn : null
}

output "terraform_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = var.create_state_bucket ? aws_dynamodb_table.terraform_state_lock[0].name : null
}

output "backend_configuration" {
  description = "Backend configuration for using the created state bucket"
  value = var.create_state_bucket ? {
    bucket         = aws_s3_bucket.terraform_state[0].id
    key            = "bootstrap/terraform.tfstate"
    region         = data.aws_region.current.name
    encrypt        = true
    dynamodb_table = aws_dynamodb_table.terraform_state_lock[0].name
  } : null
}
