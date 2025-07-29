# GitHub and Local Access Setup

This example demonstrates how to set up IAM roles that support **both** GitHub Actions via OIDC **and** local development access. This is the most flexible setup, perfect for teams that need:

- **GitHub Actions workflows** with secure OIDC authentication
- **Local development access** for developers and emergency deployments
- **Hybrid CI/CD approaches** with multiple access methods

## What This Creates

This example creates:

1. **ExecutorRole**: Can be assumed from both GitHub Actions (via OIDC) and specified AWS principals
2. **DeploymentRole**: Has deployment permissions and can only be assumed by the ExecutorRole
3. **GitHub OIDC Provider**: Enables secure authentication from GitHub Actions
4. **S3 State Backend**: Optional S3 bucket and DynamoDB table for Terraform state management

## Role Naming

With the default configuration, roles will be named:
- `my-terraform-project-TerraformExecutorRole-dev`
- `my-terraform-project-TerraformDeploymentRole-dev`

You can customize the naming by changing:
- `project_name`: Changes the prefix
- `role_name_prefix`: Changes the role type identifier (default: "Terraform")
- `environment`: Changes the suffix

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. GitHub repository (if using GitHub Actions)

## Setup Instructions

### Step 1: Configure Variables

Edit `terraform.tfvars` and update:

```hcl
# Your AWS Account ID
aws_account_id = "123456789012"

# GitHub configuration
github_org  = "your-github-org"
github_repo = "your-repo-name"

# Your AWS principals that should be able to assume the ExecutorRole
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/myuser",
  # Add more users or roles as needed
]

# Project configuration
project_name     = "my-terraform-project"
environment      = "dev" 
role_name_prefix = "Terraform"  # Can be "CI", "App", "Deploy", etc.
```

### Step 2: Initial Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 3: Configure S3 Backend (Optional but Recommended)

After the initial deployment, configure the S3 backend:

1. Note the bucket name and DynamoDB table from the outputs
2. Edit `backend.tf` and uncomment the backend configuration
3. Update the bucket name and other values
4. Migrate state to S3:

```bash
terraform init -migrate-state
```

## Usage Examples

### GitHub Actions

After deployment, add this to your GitHub Actions workflow:

```yaml
name: 'Terraform Deploy'
on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/PROJECT-TerraformExecutorRole-ENV
          aws-region: us-east-1
          
      - name: Assume deployment role
        run: |
          aws sts assume-role \
            --role-arn arn:aws:iam::ACCOUNT:role/PROJECT-TerraformDeploymentRole-ENV \
            --role-session-name github-actions
```

### Local Development

For local development, you can assume the roles directly:

```bash
# Assume the ExecutorRole first
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/my-terraform-project-TerraformExecutorRole-dev" \
  --role-session-name "local-dev-session"

# Export the credentials, then assume the DeploymentRole
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/my-terraform-project-TerraformDeploymentRole-dev" \
  --role-session-name "deployment-session"
```

## Configuration Options

### Custom Policies

Instead of using `AdministratorAccess`, you can provide custom policies:

```hcl
# In terraform.tfvars
deployment_role_policies = [
  "arn:aws:iam::aws:policy/EC2FullAccess",
  "arn:aws:iam::aws:policy/S3FullAccess"
]

# Or use inline custom policy
custom_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "ec2:*",
        "s3:*"
      ]
      Resource = "*"
    }
  ]
})
```

### GitHub OIDC Only

If you want to disable local access and only allow GitHub Actions:

```hcl
# In terraform.tfvars
trusted_aws_principals = []  # Empty list = no local access
```

### Local Access Only

If you want to disable GitHub OIDC and only allow local access:

```hcl
# In terraform.tfvars
enable_github_oidc = false
github_org         = ""
github_repo        = ""
```

## Security Considerations

1. **Least Privilege**: Use custom policies instead of `AdministratorAccess` when possible
2. **Branch Protection**: Limit `github_branches` to protected branches only
3. **Session Duration**: Configure appropriate session durations (default: 1 hour)
4. **Trusted Principals**: Only add necessary AWS principals to `trusted_aws_principals`
5. **MFA**: Consider requiring MFA for sensitive operations

## Outputs

The module provides several useful outputs:

- `executor_role_arn`: ARN of the executor role
- `deployment_role_arn`: ARN of the deployment role
- `github_oidc_provider_arn`: ARN of the GitHub OIDC provider
- `terraform_state_bucket_name`: S3 bucket for state storage
- `github_actions_example`: Example GitHub Actions configuration
- `local_aws_cli_example`: Example commands for local usage

## Troubleshooting

### GitHub Actions Issues

1. **OIDC Trust Relationship**: Ensure your GitHub org/repo matches exactly
2. **Branch Names**: Verify the branch name is in `github_branches`
3. **Permissions**: Ensure the workflow has `id-token: write` permission

### Local Access Issues

1. **User ARN**: Verify your user ARN is correctly added to `trusted_aws_principals`
2. **Credentials**: Ensure your AWS CLI is configured with proper credentials
3. **Region**: Make sure you're operating in the correct AWS region

## Clean Up

To remove all resources:

```bash
terraform destroy
```

Note: If you configured S3 backend, you may need to remove state files manually from the S3 bucket after destruction.
