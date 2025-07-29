output "deployment_role_arn" {
  description = "ARN of the DeploymentRole"
  value       = module.iam_bootstrap.deployment_role_arn
}

output "deployment_role_name" {
  description = "Name of the DeploymentRole"
  value       = module.iam_bootstrap.deployment_role_name
}

output "executor_role_arn" {
  description = "ARN of the ExecutorRole"
  value       = module.iam_bootstrap.executor_role_arn
}

output "executor_role_name" {
  description = "Name of the ExecutorRole"
  value       = module.iam_bootstrap.executor_role_name
}

output "aws_account_id" {
  description = "AWS Account ID where the roles were created"
  value       = module.iam_bootstrap.aws_account_id
}

output "aws_region" {
  description = "AWS Region where the roles were created"
  value       = module.iam_bootstrap.aws_region
}

output "local_aws_cli_example" {
  description = "Example AWS CLI commands for local development"
  value       = module.iam_bootstrap.local_aws_cli_example
}

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = module.iam_bootstrap.terraform_state_bucket_name
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = module.iam_bootstrap.terraform_state_bucket_arn
}

output "terraform_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = module.iam_bootstrap.terraform_dynamodb_table_name
}

output "backend_configuration" {
  description = "Backend configuration for using the created state bucket"
  value       = module.iam_bootstrap.backend_configuration
}
