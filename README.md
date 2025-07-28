# Terraform AWS Bootstrap Roles

🚀 **Secure, reusable IAM role automation for AWS Terraform deployments**

This module creates IAM roles that enable secure Terraform deployments from:
- **GitHub Actions** (via OIDC - no stored credentials!)
- **Local development** (via role assumption)

## 🏗️ Architecture

```
GitHub Actions / Local Machine
        ↓ (OIDC/STS authentication)
TerraformExecutorRole (Limited permissions)
        ↓ (assume role)
TerraformDeploymentRole (Custom permissions)
        ↓ (execute)
AWS Resources
```

## 🚀 Quick Start

### Automated Setup (Recommended)

**For Windows users:**
```powershell
# Run the bootstrap script
.\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "dev"
```

**For Linux/macOS users:**
```bash
# Run the bootstrap script
./bootstrap-linux.sh -a 123456789012 -p my-project -e dev
```

**Or use Make (cross-platform):**
```bash
# The Makefile detects your OS and uses the appropriate script
make bootstrap ACCOUNT_ID=123456789012 PROJECT_NAME=my-project
```

The scripts will:
- ✅ Validate your AWS credentials
- ✅ Update configuration files with your account details
- ✅ Deploy the IAM roles
- ✅ Provide next steps for configuration

### Manual Setup

If you prefer manual setup:

1. **Choose your setup type:**
   - `examples/single-account-setup/` - For both GitHub Actions + local development
   - `examples/github-oidc-setup/` - For GitHub Actions only

2. **Configure terraform.tfvars:**
   ```bash
   cd examples/single-account-setup  # or github-oidc-setup
   # Edit terraform.tfvars with your AWS account details
   ```

3. **Deploy with admin access:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## ⚙️ Configuration

### Required Settings

Update `terraform.tfvars` in your chosen example:

```hcl
# AWS Configuration
aws_account_id = "123456789012"    # Your AWS Account ID
project_name   = "my-project"      # Your project name
environment    = "dev"             # Environment (dev/staging/prod)

# For GitHub Actions
github_org      = "your-github-org"
github_repo     = "your-repo-name"
github_branches = ["main", "develop"]

# For local development (optional)
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/your-username"
]
```

### Security-First Policy Configuration

**Instead of AdministratorAccess, we use custom policies:**

```hcl
# Custom policy with only needed permissions
terraform_custom_policy_json = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "ec2:*",
        "s3:*",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole"
      ]
      Resource = "*"
    }
  ]
})
```

**Start with basic permissions and add more as needed.** See the pre-configured examples in `terraform.tfvars`.

## � Repository Structure

```
terraform-aws-bootstrap-role/
├── bootstrap-windows.ps1      # 🎯 Windows automated bootstrap script
├── bootstrap-linux.sh         # 🎯 Linux/macOS automated bootstrap script  
├── Makefile                   # Cross-platform make commands
├── README.md                  # This file
│
├── modules/iam-bootstrap/     # Core Terraform module
│   ├── main.tf               # IAM roles and policies
│   ├── variables.tf          # Configuration options
│   └── outputs.tf            # Role ARNs and setup info
│
└── examples/
    ├── single-account-setup/     # GitHub + Local development
    │   ├── main.tf
    │   ├── variables.tf
    │   └── terraform.tfvars      # 📝 Configuration template
    │
    └── github-oidc-setup/        # GitHub Actions only
        ├── main.tf
        ├── variables.tf
        └── terraform.tfvars      # 📝 Configuration template
```

## 🔐 Usage After Setup

### GitHub Actions

```yaml
name: 'Terraform Deploy'
on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
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
        terraform apply -auto-approve
```

### Local Development

```powershell
# Configure AWS CLI to use the bootstrap roles
aws configure set role_arn "arn:aws:iam::ACCOUNT:role/PROJECT-TerraformExecutorRole-ENV" --profile terraform-executor
aws configure set source_profile your-admin-profile --profile terraform-executor

# Use for Terraform operations
$env:AWS_PROFILE = "terraform-executor"
terraform plan
terraform apply
```

## 🔒 Security Features

- ✅ **No stored credentials** - Uses OIDC tokens and temporary credentials
- ✅ **Two-tier role architecture** - Executor role has minimal permissions
- ✅ **Custom policies** - No blanket AdministratorAccess
- ✅ **Branch restrictions** - Limit which GitHub branches can deploy
- ✅ **Session limits** - Configurable session duration
- ✅ **Audit trail** - All actions logged in CloudTrail

## 🛠️ Customizing Permissions

**The key to security is using custom policies instead of AdministratorAccess.**

1. **Start small** - Begin with basic EC2, S3, IAM permissions
2. **Test your Terraform** - Run `terraform plan`
3. **Add permissions as needed** - When you get "access denied" errors
4. **Iterate** - Gradually build up the exact permissions you need

Example policy evolution:
```hcl
# Week 1: Basic permissions
"Action": ["ec2:*", "s3:*"]

# Week 2: Added RDS  
"Action": ["ec2:*", "s3:*", "rds:*"]

# Week 3: Added Lambda
"Action": ["ec2:*", "s3:*", "rds:*", "lambda:*"]
```

## 🚨 First-Time Setup Requirements

**You need AWS admin access ONLY for the initial bootstrap.** After that, use the created roles.

1. **One-time admin setup** - Use your AWS admin credentials or SSO
2. **Run bootstrap** - Creates the IAM roles
3. **Switch to bootstrap roles** - Use the created roles for all future operations
4. **Secure your admin access** - Only use for emergencies or role updates

## ❓ Troubleshooting

### "Access Denied" errors
- ✅ Check your AWS Account ID in `terraform.tfvars`
- ✅ Ensure your user ARN is in `trusted_aws_principals`
- ✅ Verify you're using the right AWS region

### GitHub Actions failing
- ✅ Verify `github_org` and `github_repo` match exactly
- ✅ Check your branch is in `github_branches` list
- ✅ Ensure workflow has `id-token: write` permission

### Permission denied during Terraform operations
- ✅ Add the missing permission to `terraform_custom_policy_json`
- ✅ Update the role and try again

## 🧹 Cleanup

To remove all created resources:

```bash
cd examples/single-account-setup  # or github-oidc-setup
terraform destroy
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🎯 Quick Links

- **🚀 New user?** → See `GETTING-STARTED.md` or run the bootstrap script for your OS
- **🔧 Policy customization?** → Check `POLICY-MANAGEMENT.md`
- **❓ Issues?** → Check the troubleshooting section above

## 📁 Documentation Structure

- **`README.md`** (this file) - Complete project overview and reference
- **`GETTING-STARTED.md`** - Step-by-step setup guide for first-time users
- **`POLICY-MANAGEMENT.md`** - Guide for customizing IAM permissions
- **`S3-STATE-BACKEND.md`** - Guide for S3 state storage setup and naming conventions
- **`bootstrap-windows.ps1`** - Windows automated bootstrap script
- **`bootstrap-linux.sh`** - Linux/macOS automated bootstrap script
- **`Makefile`** - Cross-platform development commands
- **`examples/*/terraform.tfvars`** - Configuration templates with examples
---

## 🎯 Quick Links

- **� New user?** → Run `.\bootstrap.ps1` to get started
- **� Configuration help?** → Check the `terraform.tfvars` examples
- **🔒 Security questions?** → Custom policies are in the terraform.tfvars files
- **❓ Issues?** → Check the troubleshooting section above
