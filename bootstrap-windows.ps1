# Bootstrap Setup Script for Windows PowerShell
# This script helps set up the initial IAM roles using admin access

param(
    [Parameter(Mandatory=$true)]
    [string]$AccountId,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminProfile = "default"
)

Write-Host "Starting AWS IAM Bootstrap Process" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Validate AWS CLI is installed
if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Set AWS profile
$env:AWS_PROFILE = $AdminProfile
Write-Host "Using AWS Profile: $AdminProfile" -ForegroundColor Cyan

# Verify AWS credentials
Write-Host "Verifying AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "Authenticated as: $($identity.Arn)" -ForegroundColor Green
    
    # Validate account ID matches
    if ($identity.Account -ne $AccountId) {
        Write-Host "Current AWS credentials are for account $($identity.Account), but you specified $AccountId" -ForegroundColor Red
        Write-Host "Please ensure your AWS credentials match the account ID parameter" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Account ID validated: $AccountId" -ForegroundColor Green
} catch {
    Write-Host "Failed to verify AWS credentials" -ForegroundColor Red
    Write-Host "Please configure your AWS credentials using: aws configure" -ForegroundColor Yellow
    exit 1
}

# Validate account ID format
if ($AccountId -notmatch '^\d{12}$') {
    Write-Host "Invalid account ID format. Must be 12 digits." -ForegroundColor Red
    exit 1
}

# Validate Terraform is installed
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "Terraform is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Terraform: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

# Ask which example to use
Write-Host "`nAvailable setup examples:" -ForegroundColor Cyan
Write-Host "1. single-account-setup (Local development + optional GitHub)" -ForegroundColor White
Write-Host "2. github-oidc-setup (GitHub Actions focused)" -ForegroundColor White

do {
    $choice = Read-Host "Select setup type (1 or 2)"
} while ($choice -ne "1" -and $choice -ne "2")

$exampleDir = if ($choice -eq "1") { "examples/single-account-setup" } else { "examples/github-oidc-setup" }
Write-Host "Using: $exampleDir" -ForegroundColor Green

# Navigate to the selected example
Set-Location $exampleDir

# Check if terraform.tfvars exists and has the right account ID
if (Test-Path "terraform.tfvars") {
    $tfvarsContent = Get-Content "terraform.tfvars" -Raw
    if ($tfvarsContent -match 'aws_account_id\s*=\s*"(\d+)"') {
        $currentAccountId = $matches[1]
        if ($currentAccountId -eq "123456789012") {
            Write-Host "terraform.tfvars still has placeholder account ID" -ForegroundColor Yellow
            Write-Host "Updating terraform.tfvars with your account ID..." -ForegroundColor Cyan
            
            $tfvarsContent = $tfvarsContent -replace 'aws_account_id\s*=\s*"123456789012"', "aws_account_id = `"$AccountId`""
            $tfvarsContent = $tfvarsContent -replace 'project_name\s*=\s*"[^"]*"', "project_name = `"$ProjectName`""
            $tfvarsContent = $tfvarsContent -replace 'aws_region\s*=\s*"[^"]*"', "aws_region = `"$Region`""
            $tfvarsContent = $tfvarsContent -replace 'environment\s*=\s*"[^"]*"', "environment = `"$Environment`""
            
            Set-Content "terraform.tfvars" $tfvarsContent
            Write-Host "Updated terraform.tfvars" -ForegroundColor Green
        }
    }
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed" -ForegroundColor Red
    exit 1
}

# Plan the deployment
Write-Host "`nPlanning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=bootstrap.tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed" -ForegroundColor Red
    exit 1
}

# Apply the plan
Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
Write-Host "This will create the bootstrap IAM roles in your AWS account." -ForegroundColor Cyan

$confirm = Read-Host "Do you want to proceed? (y/N)"
if ($confirm -eq "y" -or $confirm -eq "Y") {
    terraform apply bootstrap.tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nBootstrap deployment completed successfully!" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Green
        
        # Show outputs
        Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
        terraform output
        
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Save the role ARNs and state bucket info from the output above" -ForegroundColor White
        Write-Host "2. OPTIONAL: Migrate to S3 backend for this bootstrap repo:" -ForegroundColor White
        Write-Host "   - Run: terraform output backend_configuration" -ForegroundColor Gray
        Write-Host "   - Update backend.tf with the output values" -ForegroundColor Gray
        Write-Host "   - Run: terraform init" -ForegroundColor Gray
        Write-Host "3. In OTHER Terraform repositories, configure these roles:" -ForegroundColor White
        Write-Host "   - Use TerraformExecutorRole for terraform plan/apply" -ForegroundColor White
        Write-Host "   - Use TerraformDeploymentRole for actual resource creation" -ForegroundColor White
        Write-Host "4. Test with your other Terraform projects using the limited roles" -ForegroundColor White
        
        Write-Host "`nFor more information, see:" -ForegroundColor Cyan
        Write-Host "- README.md for complete setup guide" -ForegroundColor White
        Write-Host "- POLICY-MANAGEMENT.md for customizing permissions" -ForegroundColor White
        Write-Host "- examples/ directories for usage examples" -ForegroundColor White
        
        Write-Host "`nTo use in OTHER Terraform repositories:" -ForegroundColor Yellow
        Write-Host "aws configure set role_arn <TerraformExecutorRole-ARN>" -ForegroundColor Gray
        Write-Host "aws configure set source_profile default" -ForegroundColor Gray
        Write-Host "Then use that profile in your other Terraform projects" -ForegroundColor Gray
        
        # Clean up plan file
        if (Test-Path "bootstrap.tfplan") {
            Remove-Item "bootstrap.tfplan"
        }
    } else {
        Write-Host "`nTerraform apply failed" -ForegroundColor Red
        Write-Host "Please check the error messages above and try again" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "`nDeployment cancelled by user" -ForegroundColor Yellow
    Write-Host "The plan file has been saved as 'bootstrap.tfplan'" -ForegroundColor Cyan
    Write-Host "You can apply it later with: terraform apply bootstrap.tfplan" -ForegroundColor Cyan
}

Write-Host "`nBootstrap script completed" -ForegroundColor Green
