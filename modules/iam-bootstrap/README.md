# IAM Bootstrap Module

This module creates the necessary IAM roles for secure Terraform deployments:

- **TerraformDeploymentRole**: The role with full administrative permissions
- **TerraformExecutorRole**: The role that can be assumed from GitHub Actions or your local machine

## Architecture

```
GitHub Actions / Local Machine
        ↓ (assume role)
TerraformExecutorRole
        ↓ (assume role)
TerraformDeploymentRole
        ↓ (execute)
AWS Resources
```

## Usage

```hcl
module "iam_bootstrap" {
  source = "./modules/iam-bootstrap"

  aws_account_id = "123456789012"
  project_name   = "my-project"
  environment    = "dev"

  # GitHub OIDC Configuration
  github_org      = "my-org"
  github_repo     = "my-repo"
  github_branches = ["main", "develop"]

  # Local development access
  trusted_aws_principals = [
    "arn:aws:iam::123456789012:user/my-username"
  ]

  tags = {
    Owner = "DevOps Team"
    Cost  = "Infrastructure"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_account_id | AWS Account ID where the roles will be created | `string` | n/a | yes |
| github_org | GitHub organization name | `string` | `""` | no |
| github_repo | GitHub repository name | `string` | `""` | no |
| github_branches | List of GitHub branches allowed to assume the role | `list(string)` | `["main", "master"]` | no |
| trusted_aws_principals | List of AWS principals that can assume the TerraformExecutorRole | `list(string)` | `[]` | no |
| project_name | Name of the project | `string` | `"terraform-bootstrap"` | no |
| environment | Environment name | `string` | `"dev"` | no |
| enable_github_oidc | Whether to enable GitHub OIDC integration | `bool` | `true` | no |
| session_duration | Maximum session duration for role assumption (in seconds) | `number` | `3600` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| terraform_deployment_role_arn | ARN of the TerraformDeploymentRole |
| terraform_executor_role_arn | ARN of the TerraformExecutorRole |
| github_oidc_provider_arn | ARN of the GitHub OIDC provider |
| github_actions_example | Example GitHub Actions workflow configuration |
| local_aws_cli_example | Example AWS CLI commands for local development |
