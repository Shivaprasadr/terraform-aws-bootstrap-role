# Replace these values with your actual AWS Account ID and desired configuration
aws_account_id = "123456789012"
aws_region     = "us-east-1"

# Project configuration
project_name     = "myapp"
environment      = "dev"
role_name_prefix = "Deploy"

# AWS principals that can assume the ExecutorRole
# Replace with your actual user/role ARNs
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/myuser",
  # "arn:aws:iam::123456789012:role/existing-role"
]

# Optional: Additional managed policies for DeploymentRole
deployment_role_policies = [
  "arn:aws:iam::aws:policy/AdministratorAccess"
]

# Optional: Custom inline policy (leave empty to use managed policies above)
custom_policy_json = ""

# S3 State backend
create_state_bucket = true
state_bucket_name   = ""  # Auto-generated if empty

# Session configuration
session_duration = 3600  # 1 hour

# Tags
tags = {
  Project     = "MyApp"
  Environment = "dev"
  Owner       = "DevTeam"
  Terraform   = "true"
}
