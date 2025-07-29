# Terraform AWS Bootstrap Roles

🚀 **Secure, parameterized IAM role automation for AWS Terraform deployments**

This module creates flexible IAM roles that enable secure Terraform deploy    └── github-and-local-access/     # GitHub + Local developmentents from:
- **GitHub Actions** (via OIDC - no stored credentials!)
- **Local ## 🎯 Quick Links

- **📱 New user?** → Run `.\scripts\bootstrap-windows.ps1` or `./scripts/bootstrap-linux.sh` to get started
- **⚙️ Configuration help?** → Check the `terraform.tfvars` examples in each example folder
- **🔒 Security questions?** → Custom policies are in the terraform.tfvars files
- **❓ Issues?** → Check the troubleshooting section abovepment** (via role assumption)
- **Other CI/CD systems** (via simple role assumption)

## 🏗️ Architecture

```
GitHub Actions / Local Machine / CI/CD
        ↓ (OIDC/STS authentication)
ExecutorRole (Limited permissions)
        ↓ (assume role)
DeploymentRole (Custom permissions)
        ↓ (execute)
AWS Resources
```

## 🔧 Flexible Role Naming

The module now supports **parameterized role names** instead of hardcoded "Terraform" prefixes:

```hcl
# Old naming (fixed):
# my-project-TerraformExecutorRole-dev
# my-project-TerraformDeploymentRole-dev

# New naming (configurable):
role_name_prefix = "Deploy"    # my-project-DeployExecutorRole-dev
role_name_prefix = "CI"        # my-project-CIExecutorRole-dev  
role_name_prefix = "App"       # my-project-AppExecutorRole-dev
```

## 📚 Examples

Three ready-to-use examples are provided:

1. **[GitHub OIDC Setup](examples/github-oidc-setup/)** - For GitHub Actions integration
2. **[GitHub and Local Access](examples/github-and-local-access/)** - Combined GitHub + local access
3. **[Simple Role Setup](examples/simple-role-setup/)** - Basic roles without GitHub OIDC

## 🚀 Quick Start

### Automated Setup (Recommended)

**For Windows users:**
```powershell
# Run the bootstrap script
.\scripts\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "dev"
```

**For Linux/macOS users:**
```bash
# Run the bootstrap script
./scripts/bootstrap-linux.sh -a 123456789012 -p my-project -e dev
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
   - `examples/github-and-local-access/` - For both GitHub Actions + local development
   - `examples/github-oidc-setup/` - For GitHub Actions only

2. **Configure terraform.tfvars:**
   ```bash
   cd examples/simple-role-setup      # For basic roles without GitHub
   cd examples/github-oidc-setup      # For GitHub Actions integration
   cd examples/github-and-local-access   # For combined setup
   # Edit terraform.tfvars with your account details
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
aws_account_id   = "123456789012"    # Your AWS Account ID
project_name     = "my-project"      # Your project name  
environment      = "dev"             # Environment (dev/staging/prod)
role_name_prefix = "Deploy"          # Role name prefix (Deploy/CI/App/etc.)

# For GitHub Actions (github-oidc-setup only)
github_org      = "your-github-org"
github_repo     = "your-repo-name" 
github_branches = ["main", "develop"]

# For local development (all examples)
trusted_aws_principals = [
  "arn:aws:iam::123456789012:user/your-username"
]
```

### Security-First Policy Configuration

**Instead of AdministratorAccess, we use custom policies:**

```hcl
# Custom policy with only needed permissions
```hcl
# Option 1: Custom inline policy (recommended)
custom_policy_json = jsonencode({
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

# Option 2: Managed policies
deployment_role_policies = [
  "arn:aws:iam::aws:policy/PowerUserAccess",
  "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
]
```

**Start with basic permissions and add more as needed.** See the pre-configured examples in `terraform.tfvars`.

## 📁 Repository Structure

```
terraform-aws-bootstrap-role/
├── Makefile                   # Cross-platform make commands
├── README.md                  # Main documentation
│
├── scripts/                   # 🎯 Automation scripts
│   ├── bootstrap-windows.ps1  # Windows automated bootstrap
│   ├── bootstrap-linux.sh     # Linux/macOS automated bootstrap
│   └── get-role-info.ps1      # Role information utility
│
├── docs/                      # 📚 Documentation
│   ├── BOOTSTRAP-PROCESS.md   # Bootstrap process details
│   ├── GETTING-STARTED.md     # Quick start guide
│   └── POLICY-MANAGEMENT.md   # Security policy examples
│
├── modules/iam-bootstrap/     # Core Terraform module
│   ├── main.tf               # IAM roles and policies
│   ├── variables.tf          # Configuration options with role_name_prefix
│   └── outputs.tf            # Role ARNs and setup info
│
└── examples/
    ├── simple-role-setup/        # Basic roles without GitHub OIDC
    │   ├── main.tf
    │   ├── variables.tf
    │   └── terraform.tfvars      # 📝 Configuration template
    │
    ├── github-and-local-access/  # GitHub + Local development
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
        role-to-assume: arn:aws:iam::ACCOUNT:role/PROJECT-DeployExecutorRole-ENV
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
aws configure set role_arn "arn:aws:iam::ACCOUNT:role/PROJECT-DeployExecutorRole-ENV" --profile terraform-executor
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
cd examples/github-and-local-access  # or github-oidc-setup
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
- **`docs/GETTING-STARTED.md`** - Step-by-step setup guide for first-time users
- **`docs/POLICY-MANAGEMENT.md`** - Guide for customizing IAM permissions
- **`docs/S3-STATE-BACKEND.md`** - Guide for S3 state storage setup and naming conventions
- **`scripts/bootstrap-windows.ps1`** - Windows automated bootstrap script
- **`scripts/bootstrap-linux.sh`** - Linux/macOS automated bootstrap script
- **`Makefile`** - Cross-platform development commands
- **`examples/*/terraform.tfvars`** - Configuration templates with examples
---

## 🎯 Quick Links

- **� New user?** → Run `.\bootstrap.ps1` to get started
- **� Configuration help?** → Check the `terraform.tfvars` examples
- **🔒 Security questions?** → Custom policies are in the terraform.tfvars files
- **❓ Issues?** → Check the troubleshooting section above
