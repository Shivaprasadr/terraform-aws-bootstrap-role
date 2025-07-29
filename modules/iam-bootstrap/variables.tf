variable "aws_account_id" {
  description = "AWS Account ID where the roles will be created"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
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

variable "trusted_aws_principals" {
  description = "List of AWS principals (users/roles) that can assume the ExecutorRole"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "terraform-bootstrap"
}

variable "role_name_prefix" {
  description = "Prefix for IAM role names (e.g., 'Terraform', 'CI', 'Deploy')"
  type        = string
  default     = "Terraform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "enable_github_oidc" {
  description = "Whether to enable GitHub OIDC integration"
  type        = bool
  default     = true
}

variable "deployment_role_policies" {
  description = "List of additional managed IAM policy ARNs to attach to DeploymentRole"
  type        = list(string)
  default     = []
}

variable "custom_policy_json" {
  description = "Custom inline policy JSON for DeploymentRole. If provided, this will be used instead of AdministratorAccess for more granular control."
  type        = string
  default     = ""
  
  validation {
    condition = var.custom_policy_json == "" || can(jsondecode(var.custom_policy_json))
    error_message = "The custom_policy_json must be valid JSON when provided."
  }
}

variable "session_duration" {
  description = "Maximum session duration for role assumption (in seconds)"
  type        = number
  default     = 3600
  validation {
    condition     = var.session_duration >= 900 && var.session_duration <= 43200
    error_message = "Session duration must be between 900 (15 minutes) and 43200 (12 hours) seconds."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
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
