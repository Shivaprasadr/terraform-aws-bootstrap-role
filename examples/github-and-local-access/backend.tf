# Backend configuration will be generated after initial setup
# Run the following steps:
# 1. Comment out this backend block initially
# 2. Run `terraform init && terraform apply`
# 3. Note the S3 bucket and DynamoDB table names from outputs
# 4. Uncomment and configure this backend block with the actual values
# 5. Run `terraform init -migrate-state` to move state to S3

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-project-terraform-state-dev-123456789012-us-east-1"
#     key            = "github-and-local-access/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "my-terraform-project-terraform-lock-dev"
#   }
# }
