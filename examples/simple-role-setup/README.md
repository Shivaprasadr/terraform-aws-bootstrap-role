# Simple IAM Role Setup Example

This example demonstrates how to create IAM roles for Terraform deployments **without** GitHub OIDC integration. This is useful when you want to:

- Set up roles for local development
- Use roles with other CI/CD systems
- Create basic IAM roles without external identity providers
- Have simple AWS-to-AWS role assumptions

## What This Creates

This example creates:

1. **ExecutorRole**: A role that can be assumed by specified AWS principals (users/roles)
2. **DeploymentRole**: A role with deployment permissions that can only be assumed by the ExecutorRole
3. **S3 State Backend**: Optional S3 bucket and DynamoDB table for Terraform state management

## Role Naming

With the default configuration, roles will be named:
- `myapp-DeployExecutorRole-dev`
- `myapp-DeployDeploymentRole-dev`

You can customize the naming by changing:
- `project_name`: Changes the prefix
- `role_name_prefix`: Changes the role type identifier (default: "Deploy")
- `environment`: Changes the suffix

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed

## Setup Instructions

### Step 1: Configure Variables

Edit `terraform.tfvars` and update:

```hcl
# Your AWS Account ID
aws_account_id = "123456789012"

# Your AWS principals that should be able to assume the ExecutorRole
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/myuser",
  # Add more users or roles as needed
]

# Project configuration
project_name     = "myapp"
environment      = "dev" 
role_name_prefix = "Deploy"  # Can be "CI", "App", "Deploy", etc.
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

### Local Development

After deployment, you can assume the roles locally:

```bash
# Assume the ExecutorRole first
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/myapp-DeployExecutorRole-dev" \
  --role-session-name "local-dev-session"

# Export the credentials, then assume the DeploymentRole
aws sts assume-role \
  --role-arn "arn:aws:iam::123456789012:role/myapp-DeployDeploymentRole-dev" \
  --role-session-name "deployment-session"
```

### CI/CD Integration

You can use these roles in any CI/CD system that supports AWS role assumption:

```yaml
# Example for GitLab CI
deploy:
  script:
    - aws sts assume-role --role-arn $EXECUTOR_ROLE_ARN --role-session-name gitlab-ci
    # Export credentials and continue with deployment
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

### Role Name Customization

```hcl
# Different prefixes for different purposes
role_name_prefix = "CI"      # Creates: myapp-CIExecutorRole-dev
role_name_prefix = "App"     # Creates: myapp-AppExecutorRole-dev
role_name_prefix = "Deploy"  # Creates: myapp-DeployExecutorRole-dev
```

## Security Considerations

1. **Least Privilege**: Use custom policies instead of `AdministratorAccess` when possible
2. **Session Duration**: Configure appropriate session durations (default: 1 hour)
3. **Trusted Principals**: Only add necessary AWS principals to `trusted_aws_principals`
4. **MFA**: Consider requiring MFA for sensitive operations

## Outputs

The module provides several useful outputs:

- `deployment_role_arn`: ARN of the deployment role
- `executor_role_arn`: ARN of the executor role
- `terraform_state_bucket_name`: S3 bucket for state storage
- `local_aws_cli_example`: Example commands for local usage

## Clean Up

To remove all resources:

```bash
terraform destroy
```

Note: If you configured S3 backend, you may need to remove state files manually from the S3 bucket after destruction.
