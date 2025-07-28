# 🚀 Getting Started Guide

**Quick setup guide for first-time users**

## 📋 Prerequisites

- ✅ AWS CLI installed and configured with admin access
- ✅ Terraform installed (version >= 1.0)
- ✅ PowerShell (for Windows users)

## 🎯 Option 1: Automated Setup (Recommended)

**Use our automated bootstrap scripts:**

**For Windows:**
```powershell
# 1. Run the bootstrap script
.\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "dev"
```

**For Linux/macOS:**
```bash
# 1. Run the bootstrap script
./bootstrap-linux.sh -a 123456789012 -p my-project -e dev
```

**Or use Make (cross-platform):**
```bash
# The Makefile detects your OS automatically
make bootstrap ACCOUNT_ID=123456789012 PROJECT_NAME=my-project
```

**All scripts will:**
- ✅ Prompt you to choose your setup type:
  - Option 1: Single account (GitHub + Local development)  
  - Option 2: GitHub OIDC only
- ✅ Validate your AWS credentials
- ✅ Update configuration files
- ✅ Deploy the IAM roles
- ✅ Show you next steps

**That's it! The scripts handle everything automatically.**

## 🎯 Option 2: Manual Setup

If you prefer manual control:

### Step 1: Choose Your Setup Type

- **`examples/single-account-setup/`** - For both GitHub Actions + local development
- **`examples/github-oidc-setup/`** - For GitHub Actions only

### Step 2: Configure terraform.tfvars

```bash
cd examples/single-account-setup  # or github-oidc-setup

# Edit terraform.tfvars with your details:
# - aws_account_id: Your 12-digit AWS account ID
# - project_name: Your project name
# - github_org: Your GitHub organization
# - github_repo: Your GitHub repository
```

### Step 3: Deploy with Admin Access

```bash
# You need AWS admin access for this ONE-TIME bootstrap
terraform init
terraform plan
terraform apply
```

## 🔐 After Setup: Using the Roles

### For GitHub Actions

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

### For Local Development

```powershell
# Configure AWS CLI to use the bootstrap roles
aws configure set role_arn "arn:aws:iam::ACCOUNT:role/PROJECT-TerraformExecutorRole-ENV" --profile terraform-executor
aws configure set source_profile your-admin-profile --profile terraform-executor

# Use for all Terraform operations
$env:AWS_PROFILE = "terraform-executor"
terraform plan
terraform apply
```

## 🔧 Customizing Permissions

**The setup uses custom IAM policies (not AdministratorAccess) for security.**

1. **Start with the default policy** in `terraform.tfvars` (covers EC2, S3, basic IAM, CloudWatch)
2. **Run your Terraform** with `terraform plan`
3. **Add permissions as needed** when you get "access denied" errors
4. **Update the role** by running `terraform apply` in the bootstrap directory

See `POLICY-MANAGEMENT.md` for detailed examples and common service permissions.

## ❓ Common Questions

**Q: Do I need admin access for every Terraform run?**
A: No! Admin access is only needed for the ONE-TIME bootstrap. After that, use the created roles.

**Q: What if I get permission denied errors?**
A: Add the required permissions to `terraform_custom_policy_json` in your terraform.tfvars and redeploy the bootstrap.

**Q: Can I use this across multiple AWS accounts?**
A: Yes! Run the bootstrap in each account with account-specific configuration.

**Q: Is this secure?**
A: Yes! It uses OIDC tokens (no stored credentials), custom policies (no blanket admin access), and a two-tier role architecture.

## 🆘 Need Help?

- **Check the main README.md** for detailed documentation
- **Review terraform.tfvars examples** in the examples directories  
- **Look at POLICY-MANAGEMENT.md** for policy customization help
- **Run `.\bootstrap.ps1`** for the easiest setup experience

---

**🎉 Ready to start?** Run the bootstrap script for your platform - it's the fastest way to get up and running!
