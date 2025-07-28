# S3 State Backend Setup Guide

This document explains the S3 state backend configuration for the Terraform AWS Bootstrap Role repository.

## 🏗️ **What Gets Created**

When you run the bootstrap with `create_state_bucket = true`, the following resources are created:

### **S3 Bucket for State Storage**
- **Name Pattern**: `{project_name}-terraform-state-{account_id}-{environment}`
- **Example**: `my-project-terraform-state-123456789012-dev`
- **Features**: 
  - Versioning enabled
  - Encryption at rest (AES256)
  - Public access blocked
  - Proper IAM permissions

### **DynamoDB Table for State Locking**
- **Name Pattern**: `{project_name}-terraform-lock-{environment}`
- **Example**: `my-project-terraform-lock-dev`
- **Features**:
  - Pay-per-request billing
  - Hash key: `LockID`

### **IAM Roles (for reference)**
- **Executor Role**: `{project_name}-TerraformExecutorRole-{environment}`
- **Deployment Role**: `{project_name}-TerraformDeploymentRole-{environment}`

## 🔄 **Workflow**

### **Phase 1: Initial Bootstrap (Local State)**
1. **Configure**: Set `create_state_bucket = true` in `terraform.tfvars`
2. **Run**: Execute bootstrap script with admin credentials
3. **Creates**: IAM roles + S3 bucket + DynamoDB table (using local state)

### **Phase 2: Migrate to S3 Backend (Optional but Recommended)**
1. **Get config**: Run `terraform output backend_configuration`
2. **Update**: Uncomment and configure the `terraform` block in `backend.tf`
3. **Migrate**: Run `terraform init` to migrate state to S3
4. **Future runs**: Will automatically use S3 backend

### **Phase 3: Use in Other Repositories**
- Use the created IAM roles in your other Terraform projects
- Optionally use the same S3 bucket for other project states (different keys)

## 📋 **Configuration Example**

After successful bootstrap, your `backend.tf` should look like:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-123456789012-dev"
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-project-terraform-lock-dev"
  }
}
```

## 🎯 **Benefits**

### **Consistent Naming**
All resources follow the same naming pattern with your project name, making them easily identifiable as belonging to your infrastructure.

### **Secure State Management**
- State files are encrypted and versioned
- State locking prevents concurrent modifications
- No accidental public access

### **Reusable Infrastructure**
- Same S3 bucket can store state for multiple related projects
- IAM roles can be used across different Terraform repositories
- Consistent security model across all projects

## 🔧 **Advanced Usage**

### **Multiple Environments**
Create separate bootstrap setups for different environments:
```bash
# Development
.\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "dev"

# Production  
.\bootstrap-windows.ps1 -AccountId "123456789012" -ProjectName "my-project" -Environment "prod"
```

This creates separate buckets and roles:
- `my-project-terraform-state-123456789012-dev`
- `my-project-terraform-state-123456789012-prod`

### **Custom Bucket Names**
Override the auto-generated name:
```hcl
state_bucket_name = "my-custom-terraform-state-bucket"
```

### **Disable State Bucket Creation**
If you want to manage state elsewhere:
```hcl
create_state_bucket = false
```

## 🚨 **Important Notes**

1. **Admin Access**: Only needed for the initial bootstrap run
2. **State Migration**: After migrating to S3, delete the local `terraform.tfstate` files
3. **Backup**: S3 versioning protects against state corruption
4. **Access**: The created IAM roles have appropriate permissions to access the state bucket

## 🎉 **Result**

After setup, you have:
- ✅ Secure IAM roles for Terraform operations
- ✅ Centralized, encrypted state storage
- ✅ State locking to prevent conflicts
- ✅ Consistent naming across all resources
- ✅ Ready to use in other Terraform projects
