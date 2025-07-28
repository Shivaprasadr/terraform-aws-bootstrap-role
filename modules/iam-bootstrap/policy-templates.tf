# Terraform Policy Templates
# 
# This file contains common IAM policy templates for different Terraform use cases.
# Copy and customize these policies based on your infrastructure needs.

locals {
  # Basic Terraform Policy - Common AWS services
  basic_terraform_policy = jsonencode({
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
      # IAM Management (limited)
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
          "iam:GetPolicy",
          "iam:ListPolicyVersions"
        ]
        Resource = "*"
      },
      # CloudWatch
      {
        Effect = "Allow"
        Action = [
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      },
      # Route53
      {
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
      },
      # Systems Manager
      {
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })

  # Advanced Terraform Policy - Includes more services
  advanced_terraform_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Include all basic permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "s3:*",
          "logs:*",
          "cloudwatch:*",
          "route53:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      # RDS Management
      {
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      # Lambda Management
      {
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      # API Gateway
      {
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "*"
      },
      # CloudFormation (for some Terraform resources)
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*"
        ]
        Resource = "*"
      },
      # Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      # KMS
      {
        Effect = "Allow"
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      # Extended IAM Management
      {
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "iam:PolicyArn" = [
              "arn:aws:iam::aws:policy/AdministratorAccess",
              "arn:aws:iam::aws:policy/IAMFullAccess"
            ]
          }
        }
      }
    ]
  })

  # Container/EKS focused policy
  container_terraform_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EKS Management
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      # ECR Management
      {
        Effect = "Allow"
        Action = [
          "ecr:*"
        ]
        Resource = "*"
      },
      # ECS Management
      {
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },
      # EC2 for container nodes
      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      # IAM for service roles
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      },
      # Application Load Balancer
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      }
    ]
  })

  # Serverless focused policy
  serverless_terraform_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Lambda
      {
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      # API Gateway
      {
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "*"
      },
      # DynamoDB
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = "*"
      },
      # S3 for Lambda packages
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      # CloudWatch for Lambda logs
      {
        Effect = "Allow"
        Action = [
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      },
      # IAM for Lambda execution roles
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      # EventBridge
      {
        Effect = "Allow"
        Action = [
          "events:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs for easy reference
output "basic_terraform_policy_json" {
  description = "Basic Terraform policy JSON for common AWS services"
  value       = local.basic_terraform_policy
}

output "advanced_terraform_policy_json" {
  description = "Advanced Terraform policy JSON with extended permissions"
  value       = local.advanced_terraform_policy
}

output "container_terraform_policy_json" {
  description = "Container-focused Terraform policy JSON for EKS/ECS workloads"
  value       = local.container_terraform_policy
}

output "serverless_terraform_policy_json" {
  description = "Serverless-focused Terraform policy JSON for Lambda/API Gateway"
  value       = local.serverless_terraform_policy
}
