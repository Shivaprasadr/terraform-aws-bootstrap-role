# Terraform Backend Configuration
# 
# This file configures the Terraform state storage backend.
# 
# FIRST RUN: Use local backend (comment out terraform block below)
# SUBSEQUENT RUNS: Use S3 backend (uncomment terraform block below)

# For first run with admin access, comment out the terraform block below
# to use local state. After the bootstrap creates the S3 bucket, you can
# uncomment and configure the backend to use the created S3 bucket.

# Uncomment the terraform block below AFTER the first successful run
# Replace the values with the output from terraform output backend_configuration

# terraform {
#   backend "s3" {
#     bucket         = "your-project-terraform-state-123456789012-dev"  # From terraform output
#     key            = "bootstrap/terraform.tfstate"
#     region         = "us-east-1"  # Your AWS region
#     encrypt        = true
#     dynamodb_table = "your-project-terraform-lock-dev"  # From terraform output
#   }
# }

# WORKFLOW:
# 1. First run: Keep terraform block commented out → Creates S3 bucket with local state
# 2. Run: terraform output backend_configuration → Get bucket and table names
# 3. Update backend.tf with the values from step 2
# 4. Run: terraform init → Migrate state to S3
# 5. Future runs will use S3 backend automatically

# NAMING CONVENTION:
# Bucket: {project_name}-terraform-state-{account_id}-{environment}
# DynamoDB: {project_name}-terraform-lock-{environment}
# Roles: {project_name}-TerraformExecutorRole-{environment}
#        {project_name}-TerraformDeploymentRole-{environment}
