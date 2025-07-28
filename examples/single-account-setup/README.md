# Single Account Setup Example

This example creates IAM roles for both **GitHub Actions** and **local development** access.

## 🚀 Quick Setup

**Option 1: Use the automated script (Recommended)**
```powershell
# From the root directory (Windows)
.\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "dev"
# Select option 1 (single-account-setup)

# From the root directory (Linux/macOS)
./bootstrap-linux.sh -a 123456789012 -p my-project -e dev
# Select option 1 (single-account-setup)
```

**Option 2: Manual setup**
```bash
# 1. Edit terraform.tfvars with your configuration
# 2. Deploy with admin access
terraform init
terraform plan  
terraform apply
```

## ⚙️ Configuration

Edit `terraform.tfvars` with your details:

```hcl
# Required
aws_account_id = "123456789012"    # Your AWS Account ID
project_name   = "my-project"      # Your project name

# For GitHub Actions
github_org      = "your-github-org"
github_repo     = "your-repo-name"
github_branches = ["main", "develop"]

# For local development
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/your-username"
]

# Security: Use custom policy instead of AdministratorAccess
terraform_custom_policy_json = jsonencode({
  # See the pre-configured example in terraform.tfvars
})
```

## 🎯 What This Creates

- **TerraformExecutorRole** - Can be assumed from GitHub Actions or your local machine
- **TerraformDeploymentRole** - Has the actual permissions to manage AWS resources
- **GitHub OIDC Provider** - Enables secure authentication from GitHub Actions

## 📚 Next Steps

- **Complete setup guide**: See `../../GETTING-STARTED.md`
- **Policy customization**: See `../../POLICY-MANAGEMENT.md`  
- **Full documentation**: See `../../README.md`
