# GitHub OIDC Setup Example

This example creates IAM roles specifically for **GitHub Actions** deployments via OIDC.

## 🚀 Quick Setup

**Option 1: Use the automated script (Recommended)**
```powershell
# From the root directory (Windows)
.\scripts\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "prod"
# Select option 2 (github-oidc-setup)

# From the root directory (Linux/macOS)  
./scripts/bootstrap-linux.sh -a 123456789012 -p my-project -e prod
# Select option 2 (github-oidc-setup)
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

# GitHub Actions (Required)
github_org      = "your-github-org"
github_repo     = "your-repo-name"
github_branches = ["main", "develop"]

# Optional: Local development access
# trusted_aws_principals = [
#   "arn:aws:iam::123456789012:user/your-username"
# ]

# Security: Use custom policy instead of AdministratorAccess
terraform_custom_policy_json = jsonencode({
  # See the pre-configured example in terraform.tfvars
})
```

## 🎯 What This Creates

- **TerraformExecutorRole** - Can be assumed from GitHub Actions via OIDC
- **TerraformDeploymentRole** - Has the actual permissions to manage AWS resources
- **GitHub OIDC Provider** - Enables secure authentication from GitHub Actions

## 🔐 GitHub Actions Usage

Add this to your workflow (`.github/workflows/terraform.yml`):

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::ACCOUNT:role/PROJECT-TerraformExecutorRole-ENV
        aws-region: us-east-1
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
    
    - name: Terraform Apply
      run: |
        terraform init
        terraform plan
        terraform apply
```

## 📚 Next Steps

- **Complete setup guide**: See `../../GETTING-STARTED.md`
- **Policy customization**: See `../../POLICY-MANAGEMENT.md`  
- **Full documentation**: See `../../README.md`
