locals {
  github_oidc_enabled = var.enable_github_oidc && var.github_org != "" && var.github_repo != ""
  
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "iam-bootstrap"
  })

  # Construct the GitHub OIDC subject conditions
  github_subjects = [
    for branch in var.github_branches : 
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
  ]
}

# Data source to get AWS caller identity
data "aws_caller_identity" "current" {}

# Data source to get AWS region
data "aws_region" "current" {}

# GitHub OIDC Identity Provider (only create if GitHub integration is enabled)
resource "aws_iam_openid_connect_provider" "github" {
  count = local.github_oidc_enabled ? 1 : 0

  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = local.common_tags
}

# TerraformDeploymentRole - The role with actual permissions
resource "aws_iam_role" "terraform_deployment_role" {
  name               = "${var.project_name}-TerraformDeploymentRole-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/${var.project_name}-TerraformExecutorRole-${var.environment}"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }
    ]
  })

  max_session_duration = var.session_duration

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-TerraformDeploymentRole-${var.environment}"
    Type = "DeploymentRole"
  })
}

# # Attach AdminAccess policy to TerraformDeploymentRole (if no custom policies specified)
# resource "aws_iam_role_policy_attachment" "terraform_deployment_admin" {
#   count      = length(var.terraform_deployment_role_policies) == 0 ? 1 : 0
#   role       = aws_iam_role.terraform_deployment_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# Custom inline policy for TerraformDeploymentRole (recommended approach)
resource "aws_iam_role_policy" "terraform_deployment_custom" {
  count = var.terraform_custom_policy_json != "" ? 1 : 0
  name  = "${var.project_name}-TerraformDeploymentPolicy-${var.environment}"
  role  = aws_iam_role.terraform_deployment_role.id
  policy = var.terraform_custom_policy_json
}

# Attach additional managed policies to TerraformDeploymentRole if specified
resource "aws_iam_role_policy_attachment" "terraform_deployment_additional" {
  count      = length(var.terraform_deployment_role_policies)
  role       = aws_iam_role.terraform_deployment_role.name
  policy_arn = var.terraform_deployment_role_policies[count.index]
}

# TerraformExecutorRole - The role that can be assumed from GitHub or personal machine
resource "aws_iam_role" "terraform_executor_role" {
  name = "${var.project_name}-TerraformExecutorRole-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # GitHub OIDC trust policy (if enabled)
      local.github_oidc_enabled ? [{
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_subjects
          }
        }
      }] : [],
      # AWS principals trust policy (for personal machine access)
      length(var.trusted_aws_principals) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_aws_principals
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }] : []
    )
  })

  max_session_duration = var.session_duration

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-TerraformExecutorRole-${var.environment}"
    Type = "ExecutorRole"
  })
}

# IAM policy for TerraformExecutorRole - only allows assuming TerraformDeploymentRole
resource "aws_iam_role_policy" "terraform_executor_policy" {
  name = "${var.project_name}-TerraformExecutorPolicy-${var.environment}"
  role = aws_iam_role.terraform_executor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.terraform_deployment_role.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "sts:TagSession"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create a policy document for easy reference
data "aws_iam_policy_document" "terraform_executor_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform_deployment_role.arn]
  }
}

# Generate a unique bucket name if not provided
locals {
  bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "${var.project_name}-terraform-state-${var.aws_account_id}-${var.environment}"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_state_bucket ? 1 : 0
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
    Type = "TerraformState"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.create_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  count          = var.create_state_bucket ? 1 : 0
  name           = "${var.project_name}-terraform-lock-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-terraform-lock-${var.environment}"
    Type = "TerraformStateLock"
  })
}
