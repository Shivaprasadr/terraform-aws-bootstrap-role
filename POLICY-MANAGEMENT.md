# Custom IAM Policy Guide

🔒 **Instead of using AdministratorAccess, create custom policies with only the permissions you need.**

## 🎯 Why Custom Policies?

- ✅ **Security**: Only grant permissions Terraform actually needs
- ✅ **Compliance**: Meet security audit and organizational requirements  
- ✅ **Visibility**: Clear understanding of what Terraform can do
- ✅ **Control**: Add/remove permissions as your infrastructure evolves

## 🚀 Quick Start

### 1. Start with Basic Permissions

The examples in `terraform.tfvars` include a basic policy covering common AWS services:

```hcl
terraform_custom_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [
    # EC2 Management (VMs, Load Balancers, Auto Scaling)
    {
      Effect = "Allow"
      Action = [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ]
      Resource = "*"
    },
    # S3 Management (Storage)
    {
      Effect = "Allow"
      Action = ["s3:*"]
      Resource = "*"
    },
    # Basic IAM (for Terraform-managed roles)
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
```

### 2. Test Your Infrastructure

```bash
terraform plan
# If you see "access denied" errors, you need to add more permissions
```

### 3. Add Permissions as Needed

When Terraform fails with permission errors, add the required services:

## 📋 Common Service Additions

### Database Services (RDS)
```json
{
  "Effect": "Allow",
  "Action": ["rds:*"],
  "Resource": "*"
}
```

### Serverless (Lambda)
```json
{
  "Effect": "Allow",
  "Action": [
    "lambda:*",
    "apigateway:*",
    "events:*"
  ],
  "Resource": "*"
}
```

### Containers (ECS/EKS)
```json
{
  "Effect": "Allow",
  "Action": [
    "ecs:*",
    "eks:*",
    "ecr:*"
  ],
  "Resource": "*"
}
```

### DNS (Route53)
```json
{
  "Effect": "Allow",
  "Action": ["route53:*"],
  "Resource": "*"
}
```

### Content Delivery (CloudFront)
```json
{
  "Effect": "Allow",
  "Action": [
    "cloudfront:*",
    "acm:*"
  ],
  "Resource": "*"
}
```

## 🔄 Iterative Development Process

1. **Start Small** - Use the basic policy from terraform.tfvars
2. **Deploy** - Run `terraform apply` with your current permissions
3. **Add Services** - When you add new AWS resources to your Terraform
4. **Test** - Run `terraform plan` to see if new permissions are needed
5. **Update Policy** - Add the required permissions to your custom policy
6. **Repeat** - Continue this cycle as your infrastructure grows

## 🛠️ Updating Policies

### Method 1: Update terraform.tfvars and Redeploy

```bash
# Edit your terraform.tfvars file to add new permissions
# Then redeploy the bootstrap roles
terraform apply
```

### Method 2: Use Managed Policies (Alternative)

Instead of custom JSON, you can use AWS managed policies:

```hcl
# In terraform.tfvars, leave terraform_custom_policy_json empty and use:
terraform_deployment_role_policies = [
  "arn:aws:iam::aws:policy/PowerUserAccess",     # Everything except IAM users/groups
  "arn:aws:iam::aws:policy/IAMReadOnlyAccess"    # Read-only IAM access
]
```

## 🚨 Security Best Practices

### DO ✅
- Start with minimal permissions and add as needed
- Test policies in development environments first
- Use specific actions instead of wildcards when possible
- Review and audit permissions regularly
- Document why each permission is needed

### DON'T ❌
- Grant `"*"` permissions unless absolutely necessary
- Use AdministratorAccess in production
- Add permissions you don't understand
- Skip testing policy changes

## 🔍 Debugging Permission Issues

### Common Error Messages

**"User is not authorized to perform: [action]"**
→ Add the specific action to your policy

**"Access denied"**
→ Check CloudTrail logs for the exact permission needed

**"Invalid action"**
→ Verify the action name is correct (check AWS documentation)

### Useful Commands for Testing

```bash
# Test role assumption
aws sts get-caller-identity

# Test specific AWS actions
aws ec2 describe-instances
aws s3 ls
aws iam list-roles
```

## 📊 Example: Complete Web Application Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*", 
        "autoscaling:*",
        "rds:*",
        "s3:*",
        "cloudfront:*",
        "route53:*",
        "acm:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "logs:*",
        "cloudwatch:*",
        "ssm:GetParameter",
        "ssm:PutParameter"
      ],
      "Resource": "*"
    }
  ]
}
```

This policy supports:
- Web servers (EC2, Load Balancers)
- Databases (RDS)
- File storage (S3)
- CDN (CloudFront)
- DNS (Route53)
- SSL certificates (ACM)
- Basic IAM role management
- Monitoring and logging

## 🎯 Key Takeaway

**Custom policies require an iterative approach.** Start simple, test regularly, and add permissions as your infrastructure needs grow. This gives you the perfect balance of security and functionality.
```json
{
  "Version": "2012-10-17", 
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "s3:*",
        "logs:*",
        "events:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Container Stack**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow", 
      "Action": [
        "eks:*",
        "ecr:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🔄 **Iterative Development Process**

### **1. Start Minimal**
```hcl
# Start with just what you know you need
terraform_custom_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = ["ec2:*", "s3:*"]
      Resource = "*"
    }
  ]
})
```

### **2. Run Terraform and Identify Missing Permissions**
```bash
terraform plan
# Error: User is not authorized to perform: iam:CreateRole
```

### **3. Add Required Permissions**
```hcl
# Add IAM permissions to your policy
{
  Effect = "Allow"
  Action = [
    "iam:CreateRole",
    "iam:DeleteRole", 
    "iam:GetRole",
    "iam:PassRole"
  ]
  Resource = "*"
}
```

### **4. Update and Redeploy**
```bash
terraform apply
# This will update the role policy
```

## 🛠️ **Policy Management Strategies**

### **Strategy 1: Service-Based Policies**
```hcl
# Separate managed policies for different services
terraform_deployment_role_policies = [
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
]
```

### **Strategy 2: Environment-Specific Policies**
```hcl
# Different policies for different environments
terraform_custom_policy_json = var.environment == "prod" ? 
  local.production_policy : local.development_policy
```

### **Strategy 3: Versioned Policies**
```hcl
# Keep policy versions in your Terraform code
locals {
  policy_v1 = jsonencode({ ... })  # Basic permissions
  policy_v2 = jsonencode({ ... })  # Added RDS
  policy_v3 = jsonencode({ ... })  # Added Lambda
  
  current_policy = local.policy_v3
}

terraform_custom_policy_json = local.current_policy
```

## 🔍 **Debugging Permission Issues**

### **1. Enable CloudTrail Logging**
```hcl
# In your Terraform config, you can add CloudTrail to see what permissions are being used
resource "aws_cloudtrail" "terraform_audit" {
  name           = "${var.project_name}-terraform-audit"
  s3_bucket_name = aws_s3_bucket.terraform_audit.bucket
}
```

### **2. Use AWS CLI to Test Permissions**
```bash
# Test if the role can perform specific actions
aws sts assume-role --role-arn "your-deployment-role-arn" --role-session-name test

# Then test specific permissions
aws ec2 describe-instances
aws s3 ls
```

### **3. Use Policy Simulator**
```bash
# AWS provides a policy simulator to test permissions
# https://policysim.aws.amazon.com/
```

## 📊 **Best Practices**

### **✅ Do's**
- Start with minimal permissions and add as needed
- Use specific resource ARNs when possible instead of "*"
- Regular audit of permissions (remove unused ones)
- Version your policies in Git
- Test policy changes in dev environment first

### **❌ Don'ts**  
- Don't use "*" for all actions unless necessary
- Don't add permissions "just in case"
- Don't ignore permission denied errors (fix them properly)
- Don't use `AdministratorAccess` in production

## 🔄 **Migration from AdminAccess**

### **Step 1: Enable Logging**
```hcl
# Add CloudTrail to see what permissions are actually used
```

### **Step 2: Analyze Usage**
```bash
# Review CloudTrail logs to see what API calls Terraform makes
aws logs filter-log-events \
  --log-group-name CloudTrail/TerraformActions \
  --filter-pattern "{ $.userIdentity.arn = \"*TerraformDeploymentRole*\" }"
```

### **Step 3: Create Custom Policy**
```hcl
# Based on actual usage, create a minimal policy
```

### **Step 4: Gradual Rollout**
```hcl
# Test in dev first, then staging, then production
```

## 🎯 **Example: Complete Policy Evolution**

### **Phase 1: Basic Web App**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*", "s3:*"],
      "Resource": "*"
    }
  ]
}
```

### **Phase 2: Add Database**
```json
{
  "Version": "2012-10-17", 
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*", "s3:*", "rds:*"],
      "Resource": "*"
    }
  ]
}
```

### **Phase 3: Add Load Balancer**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow", 
      "Action": [
        "ec2:*", 
        "s3:*", 
        "rds:*",
        "elasticloadbalancing:*",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

This approach gives you **granular control** over what your Terraform deployment role can do, making your infrastructure **more secure** and **compliant** while still being **manageable** and **updateable**! 🔒
