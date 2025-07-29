# AWS Configuration
aws_region     = "us-east-1"  # Change to your preferred region
aws_account_id = "123456789012"  # REQUIRED: Replace with your AWS Account ID

# Project Configuration
project_name     = "my-github-terraform"  # Change to your project name
environment      = "prod"  # Change to your environment
role_name_prefix = "Terraform"  # Prefix for role names (Terraform, CI, Deploy, etc.)

# Terraform State Configuration
create_state_bucket = true  # Set to true to create S3 bucket for state storage
# state_bucket_name = "custom-bucket-name"  # Optional: Override auto-generated bucket name
# Auto-generated name format: {project_name}-terraform-state-{account_id}-{environment}

# GitHub Configuration - REQUIRED for OIDC setup
github_org      = "your-github-org"      # REQUIRED: Replace with your GitHub organization
github_repo     = "your-github-repo"     # REQUIRED: Replace with your GitHub repository
github_branches = ["main", "develop"]    # Branches allowed to deploy

# Optional: Local Development Access
# Uncomment and add your AWS user ARN if you also want local development access
# trusted_aws_principals = [
#   "arn:aws:iam::123456789012:user/your-username"
# ]

# Session Configuration
session_duration = 3600  # 1 hour

# Deployment Role Permissions
# 
# Option 1: Use AdministratorAccess (default - not recommended for production)
# Leave custom_policy_json empty and deployment_role_policies empty
#
# Option 2: Use a custom inline policy (RECOMMENDED)
# Uncomment and customize one of the policy templates below:

# Basic policy for common AWS services (EC2, S3, IAM basics, CloudWatch)
custom_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [
    # EC2 Management
    {
      Effect = "Allow"
      Action = [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ]
      Resource = "*"
    },
    # S3 Management
    {
      Effect = "Allow"
      Action = [
        "s3:*"
      ]
      Resource = "*"
    },
    # IAM Management (limited to what Terraform typically needs)
    {
      Effect = "Allow"
      Action = [
        "iam:CreateRole",
        "iam:DeleteRole", 
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy"
      ]
      Resource = "*"
    },
    # CloudWatch and Logging
    {
      Effect = "Allow"
      Action = [
        "logs:*",
        "cloudwatch:*"
      ]
      Resource = "*"
    },
    # Systems Manager Parameter Store
    {
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:PutParameter",
        "ssm:DeleteParameter"
      ]
      Resource = "*"
    }
  ]
})

# Option 3: Use specific managed policies (alternative to custom policy above)
# If you prefer managed policies over custom inline policies, use this instead:
deployment_role_policies = []
# Example managed policies you could add:
# deployment_role_policies = [
#   "arn:aws:iam::aws:policy/PowerUserAccess",     # Everything except IAM users/groups  
#   "arn:aws:iam::aws:policy/IAMReadOnlyAccess"    # Read-only IAM access
# ]

# Add more services as needed by uncommenting and modifying:
# For RDS: Add "rds:*"
# For Lambda: Add "lambda:*"  
# For EKS: Add "eks:*", "ecr:*"
# For Route53: Add "route53:*"

# Additional Tags
tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Purpose     = "GitHub Actions Terraform Deployment"
  Environment = "prod"
}
