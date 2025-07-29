variable "aws_region"variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "role_name_prefix" {
  description = "Prefix for IAM role names (e.g., 'Terraform', 'CI', 'Deploy')"
  type        = string
  default     = "Terraform"
} description = "AWS region to deploy resources"
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
  default     = "github-terraform-deploy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  validation {
    condition     = var.github_org != ""
    error_message = "GitHub organization name is required for OIDC setup."
  }
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  validation {
    condition     = var.github_repo != ""
    error_message = "GitHub repository name is required for OIDC setup."
  }
}

variable "github_branches" {
  description = "List of GitHub branches allowed to assume the role"
  type        = list(string)
  default     = ["main"]
}

variable "trusted_aws_principals" {
  description = "List of AWS principals (users/roles) that can assume the TerraformExecutorRole (optional for GitHub-only setup)"
  type        = list(string)
  default     = []
}

variable "session_duration" {
  description = "Maximum session duration for role assumption (in seconds)"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "custom_policy_json" {
  description = "Custom IAM policy JSON for the deployment role (optional)"
  type        = string
  default     = ""
  
  validation {
    condition = var.custom_policy_json == "" || can(jsondecode(var.custom_policy_json))
    error_message = "The custom_policy_json must be valid JSON when provided."
  }
}

variable "deployment_role_policies" {
  description = "List of managed policy ARNs to attach to the deployment role"
  type        = list(string)
  default     = []
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
