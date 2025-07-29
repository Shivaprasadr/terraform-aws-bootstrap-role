variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID where the roles will be created"
  type        = string
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "Environment name (dev, staging, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "role_name_prefix" {
  description = "Prefix for IAM role names (e.g., 'Deploy', 'CI', 'App')"
  type        = string
  default     = "Deploy"
}

variable "trusted_aws_principals" {
  description = "List of AWS principals (users/roles ARNs) that can assume the ExecutorRole"
  type        = list(string)
  default     = []
  # Example:
  # [
  #   "arn:aws:iam::123456789012:user/myuser",
  #   "arn:aws:iam::123456789012:role/myrole"
  # ]
}

variable "deployment_role_policies" {
  description = "List of additional managed IAM policy ARNs to attach to DeploymentRole"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

variable "custom_policy_json" {
  description = "Custom inline policy JSON for DeploymentRole. If provided, this will be used instead of the managed policies."
  type        = string
  default     = ""
}

variable "session_duration" {
  description = "Maximum session duration for role assumption (in seconds)"
  type        = number
  default     = 3600
}

variable "create_state_bucket" {
  description = "Whether to create an S3 bucket for Terraform state storage"
  type        = bool
  default     = true
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (will be auto-generated if not provided)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "Simple Role Setup"
    Terraform   = "true"
    Purpose     = "IAM Bootstrap"
  }
}
