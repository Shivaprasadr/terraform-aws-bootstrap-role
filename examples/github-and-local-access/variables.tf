variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID where the roles will be created"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "terraform-bootstrap"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "role_name_prefix" {
  description = "Prefix for IAM role names (e.g., 'Terraform', 'CI', 'Deploy')"
  type        = string
  default     = "Terraform"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_branches" {
  description = "List of GitHub branches allowed to assume the role"
  type        = list(string)
  default     = ["main", "master"]
}

variable "enable_github_oidc" {
  description = "Whether to enable GitHub OIDC integration"
  type        = bool
  default     = true
}

variable "trusted_aws_principals" {
  description = "List of AWS principals (users/roles) that can assume the ExecutorRole"
  type        = list(string)
  default     = []
}

variable "custom_policy_json" {
  description = "Custom inline policy JSON for DeploymentRole. If provided, this will be used instead of AdministratorAccess."
  type        = string
  default     = ""
}

variable "deployment_role_policies" {
  description = "List of managed IAM policy ARNs to attach to DeploymentRole"
  type        = list(string)
  default     = []
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
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
