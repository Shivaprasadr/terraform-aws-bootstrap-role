#!/bin/bash

# Bootstrap Setup Script for Linux/macOS
# This script helps set up the initial IAM roles using admin access

set -e  # Exit on any error

# Default values
ENVIRONMENT="dev"
REGION="us-east-1"
ADMIN_PROFILE="default"

# Function to display usage
usage() {
    echo "Usage: $0 -a ACCOUNT_ID -p PROJECT_NAME [-e ENVIRONMENT] [-r REGION] [-P ADMIN_PROFILE]"
    echo ""
    echo "Required:"
    echo "  -a ACCOUNT_ID     AWS Account ID (12 digits)"
    echo "  -p PROJECT_NAME   Project name for resource naming"
    echo ""
    echo "Optional:"
    echo "  -e ENVIRONMENT    Environment name (default: dev)"
    echo "  -r REGION         AWS region (default: us-east-1)"
    echo "  -P ADMIN_PROFILE  AWS CLI profile to use (default: default)"
    echo "  -h                Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -a 123456789012 -p my-project -e dev"
    exit 1
}

# Parse command line arguments
while getopts "a:p:e:r:P:h" opt; do
    case $opt in
        a) ACCOUNT_ID="$OPTARG" ;;
        p) PROJECT_NAME="$OPTARG" ;;
        e) ENVIRONMENT="$OPTARG" ;;
        r) REGION="$OPTARG" ;;
        P) ADMIN_PROFILE="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
    esac
done

# Check required parameters
if [[ -z "$ACCOUNT_ID" || -z "$PROJECT_NAME" ]]; then
    echo "❌ Error: Account ID and Project Name are required"
    usage
fi

# Validate Account ID format
if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    echo "❌ Error: Account ID must be a 12-digit number"
    exit 1
fi

echo "🚀 Starting AWS IAM Bootstrap Process"
echo "====================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed or not in PATH"
    echo "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

# Set AWS profile
export AWS_PROFILE="$ADMIN_PROFILE"
echo "📋 Using AWS Profile: $ADMIN_PROFILE"

# Verify AWS credentials
echo "🔍 Verifying AWS credentials..."
if ! IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null); then
    echo "❌ Failed to verify AWS credentials. Please check your configuration."
    echo "Run: aws configure --profile $ADMIN_PROFILE"
    exit 1
fi

CURRENT_ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
USER_ARN=$(echo "$IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)

echo "✅ Authenticated as: $USER_ARN"

if [[ "$CURRENT_ACCOUNT" != "$ACCOUNT_ID" ]]; then
    echo "⚠️  WARNING: Connected to account $CURRENT_ACCOUNT but targeting $ACCOUNT_ID"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user"
        exit 1
    fi
fi

# Check if we're in the right directory
if [[ ! -d "examples" ]]; then
    echo "❌ Please run this script from the terraform-aws-bootstrap-role root directory"
    exit 1
fi

# Ask which example to use
echo ""
echo "📁 Available setup examples:"
echo "1. github-and-local-access (Local development + optional GitHub)"
echo "2. github-oidc-setup (GitHub Actions focused)"

while true; do
    read -p "Select setup type (1 or 2): " choice
    case $choice in
        1) EXAMPLE_DIR="examples/github-and-local-access"; break ;;
        2) EXAMPLE_DIR="examples/github-oidc-setup"; break ;;
        *) echo "Please enter 1 or 2" ;;
    esac
done

echo "✅ Using: $EXAMPLE_DIR"

# Navigate to the selected example
cd "$EXAMPLE_DIR"

# Check if terraform.tfvars exists and has the right account ID
if [[ -f "terraform.tfvars" ]]; then
    if grep -q 'aws_account_id.*=.*"123456789012"' terraform.tfvars; then
        echo "⚠️  terraform.tfvars still has placeholder account ID"
        echo "🔧 Updating terraform.tfvars with your account ID..."
        
        # Use sed to update the terraform.tfvars file
        sed -i.bak \
            -e "s/aws_account_id[[:space:]]*=[[:space:]]*\"123456789012\"/aws_account_id = \"$ACCOUNT_ID\"/" \
            -e "s/project_name[[:space:]]*=[[:space:]]*\"[^\"]*\"/project_name = \"$PROJECT_NAME\"/" \
            -e "s/aws_region[[:space:]]*=[[:space:]]*\"[^\"]*\"/aws_region = \"$REGION\"/" \
            -e "s/environment[[:space:]]*=[[:space:]]*\"[^\"]*\"/environment = \"$ENVIRONMENT\"/" \
            terraform.tfvars
        
        # Remove backup file
        rm -f terraform.tfvars.bak
        
        echo "✅ Updated terraform.tfvars"
    fi
fi

# Initialize Terraform
echo ""
echo "🔄 Initializing Terraform..."
if ! terraform init; then
    echo "❌ Terraform init failed"
    exit 1
fi

# Plan the deployment
echo ""
echo "📋 Creating Terraform plan..."
if ! terraform plan -out=bootstrap.tfplan; then
    echo "❌ Terraform plan failed"
    exit 1
fi

# Confirm before applying
echo ""
echo "🚨 IMPORTANT: This will create IAM roles in your AWS account"
echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"

read -p $'\nProceed with bootstrap? (yes/no): ' confirm
if [[ "$confirm" != "yes" ]]; then
    echo "❌ Bootstrap cancelled"
    rm -f bootstrap.tfplan
    exit 1
fi

# Apply the bootstrap
echo ""
echo "🚀 Applying bootstrap configuration..."
if terraform apply bootstrap.tfplan; then
    echo ""
    echo "✅ Bootstrap completed successfully!"
    echo "====================================="
    
    # Generate role ARNs
    EXECUTOR_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME}-TerraformExecutorRole-${ENVIRONMENT}"
    DEPLOYMENT_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME}-TerraformDeploymentRole-${ENVIRONMENT}"
    
    echo ""
    echo "📝 Next Steps:"
    echo "1. Save the role ARNs and state bucket info from the output above"
    echo "2. OPTIONAL: Migrate to S3 backend for this bootstrap repo:"
    echo "   terraform output backend_configuration"
    echo "   # Update backend.tf with the output values, then run: terraform init"  
    echo "3. Configure AWS CLI to use the roles in OTHER Terraform repositories:"
    echo "   aws configure set role_arn \"$EXECUTOR_ROLE_ARN\" --profile terraform-executor"
    echo "   aws configure set source_profile $ADMIN_PROFILE --profile terraform-executor"
    
    echo ""
    echo "4. In your OTHER Terraform projects, use:"
    echo "   export AWS_PROFILE=\"terraform-executor\""
    echo "   terraform plan    # Uses limited permissions"
    echo "   terraform apply   # Uses deployment role automatically"
    
    echo ""
    echo "5. Test the role assumption:"
    echo "   aws sts get-caller-identity --profile terraform-executor"
    
    echo ""
    echo "4. Customize permissions as needed:"
    echo "   📖 See POLICY-MANAGEMENT.md for adding AWS services"
    
    echo ""
    echo "📋 Created Roles:"
    echo "Executor Role:  $EXECUTOR_ROLE_ARN"
    echo "Deployment Role: $DEPLOYMENT_ROLE_ARN"
    
    echo ""
    echo "📚 Documentation:"
    echo "• GETTING-STARTED.md - Setup guide for first-time users"
    echo "• POLICY-MANAGEMENT.md - Guide for customizing IAM permissions"
    echo "• README.md - Complete project documentation"
    
else
    echo ""
    echo "❌ Bootstrap failed"
    rm -f bootstrap.tfplan
    exit 1
fi

# Clean up
rm -f bootstrap.tfplan

echo ""
echo "🎉 Bootstrap process complete!"
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    print_status "AWS CLI is installed: $(aws --version)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    local caller_info=$(aws sts get-caller-identity)
    local account_id=$(echo $caller_info | jq -r '.Account')
    local user_arn=$(echo $caller_info | jq -r '.Arn')
    
    print_status "AWS credentials configured"
    print_info "Account ID: $account_id"
    print_info "User/Role: $user_arn"
    
    echo ""
}

# Function to setup single account configuration
setup_single_account() {
    print_header "Single Account Setup (GitHub + Local)"
    
    local config_dir="examples/github-and-local-access"
    local config_file="$config_dir/terraform.tfvars.local"
    
    if [ -f "$config_file" ]; then
        print_warning "Configuration file already exists: $config_file"
        read -p "Do you want to reconfigure? (y/N): " reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            print_info "Using existing configuration"
        else
            rm "$config_file"
        fi
    fi
    
    if [ ! -f "$config_file" ]; then
        print_info "Creating configuration file..."
        cp "$config_dir/terraform.tfvars" "$config_file"
        
        # Get AWS account info
        local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
        local user_arn=$(aws sts get-caller-identity --query 'Arn' --output text)
        local region=$(aws configure get region || echo "us-east-1")
        
        # Interactive configuration
        echo ""
        read -p "Project name [$GREEN$(basename $(pwd))$NC]: " project_name
        project_name=${project_name:-$(basename $(pwd))}
        
        read -p "Environment [${GREEN}dev$NC]: " environment
        environment=${environment:-dev}
        
        read -p "AWS Region [${GREEN}$region$NC]: " aws_region
        aws_region=${aws_region:-$region}
        
        echo ""
        print_info "GitHub Configuration (leave empty to disable GitHub OIDC)"
        read -p "GitHub Organization: " github_org
        read -p "GitHub Repository: " github_repo
        
        # Update configuration file
        sed -i.bak \
            -e "s/123456789012/$account_id/g" \
            -e "s/your-username/$(echo $user_arn | cut -d'/' -f2)/g" \
            -e "s/us-east-1/$aws_region/g" \
            -e "s/my-terraform-project/$project_name/g" \
            -e "s/\"dev\"/\"$environment\"/g" \
            "$config_file"
        
        if [ ! -z "$github_org" ] && [ ! -z "$github_repo" ]; then
            sed -i.bak \
                -e "s/your-github-org/$github_org/g" \
                -e "s/your-github-repo/$github_repo/g" \
                -e "s/enable_github_oidc = true/enable_github_oidc = true/g" \
                "$config_file"
        else
            sed -i.bak \
                -e "s/enable_github_oidc = true/enable_github_oidc = false/g" \
                "$config_file"
        fi
        
        rm "$config_file.bak"
        
        print_status "Configuration file created: $config_file"
        print_info "Please review and modify the configuration if needed"
        
        read -p "Do you want to edit the configuration now? (y/N): " edit_config
        if [[ $edit_config =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} "$config_file"
        fi
    fi
    
    # Deploy
    print_info "Deploying IAM roles..."
    cd "$config_dir"
    
    terraform init
    print_status "Terraform initialized"
    
    terraform plan -var-file="terraform.tfvars.local"
    
    echo ""
    read -p "Do you want to apply these changes? (y/N): " apply_changes
    if [[ $apply_changes =~ ^[Yy]$ ]]; then
        terraform apply -var-file="terraform.tfvars.local"
        print_status "Deployment complete!"
    else
        print_warning "Deployment cancelled"
    fi
    
    cd - > /dev/null
}

# Function to setup GitHub OIDC only
setup_github_oidc() {
    print_header "GitHub OIDC Setup (Actions Only)"
    
    local config_dir="examples/github-oidc-setup"
    local config_file="$config_dir/terraform.tfvars.local"
    
    if [ -f "$config_file" ]; then
        print_warning "Configuration file already exists: $config_file"
        read -p "Do you want to reconfigure? (y/N): " reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            print_info "Using existing configuration"
        else
            rm "$config_file"
        fi
    fi
    
    if [ ! -f "$config_file" ]; then
        print_info "Creating configuration file..."
        cp "$config_dir/terraform.tfvars" "$config_file"
        
        # Get AWS account info
        local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
        local region=$(aws configure get region || echo "us-east-1")
        
        # Interactive configuration
        echo ""
        read -p "Project name [$GREEN$(basename $(pwd))$NC]: " project_name
        project_name=${project_name:-$(basename $(pwd))}
        
        read -p "Environment [${GREEN}prod$NC]: " environment
        environment=${environment:-prod}
        
        read -p "AWS Region [${GREEN}$region$NC]: " aws_region
        aws_region=${aws_region:-$region}
        
        echo ""
        print_info "GitHub Configuration (required for OIDC)"
        while [ -z "$github_org" ]; do
            read -p "GitHub Organization: " github_org
            if [ -z "$github_org" ]; then
                print_error "GitHub organization is required for OIDC setup"
            fi
        done
        
        while [ -z "$github_repo" ]; do
            read -p "GitHub Repository: " github_repo
            if [ -z "$github_repo" ]; then
                print_error "GitHub repository is required for OIDC setup"
            fi
        done
        
        # Update configuration file
        sed -i.bak \
            -e "s/123456789012/$account_id/g" \
            -e "s/us-east-1/$aws_region/g" \
            -e "s/my-github-terraform/$project_name/g" \
            -e "s/\"prod\"/\"$environment\"/g" \
            -e "s/your-github-org/$github_org/g" \
            -e "s/your-github-repo/$github_repo/g" \
            "$config_file"
        
        rm "$config_file.bak"
        
        print_status "Configuration file created: $config_file"
        print_info "Please review and modify the configuration if needed"
        
        read -p "Do you want to edit the configuration now? (y/N): " edit_config
        if [[ $edit_config =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} "$config_file"
        fi
    fi
    
    # Deploy
    print_info "Deploying IAM roles..."
    cd "$config_dir"
    
    terraform init
    print_status "Terraform initialized"
    
    terraform plan -var-file="terraform.tfvars.local"
    
    echo ""
    read -p "Do you want to apply these changes? (y/N): " apply_changes
    if [[ $apply_changes =~ ^[Yy]$ ]]; then
        terraform apply -var-file="terraform.tfvars.local"
        print_status "Deployment complete!"
        print_info "Check the output above for GitHub Actions workflow configuration"
    else
        print_warning "Deployment cancelled"
    fi
    
    cd - > /dev/null
}

# Function to show cleanup options
cleanup_resources() {
    print_header "Cleanup Resources"
    
    echo "Available cleanup options:"
    echo "1) Single account setup"
    echo "2) GitHub OIDC setup"
    echo "3) Cancel"
    
    read -p "Choose option (1-3): " cleanup_option
    
    case $cleanup_option in
        1)
            if [ -f "examples/github-and-local-access/terraform.tfvars.local" ]; then
                cd "examples/github-and-local-access"
                print_warning "This will destroy all created IAM roles and resources"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    terraform destroy -var-file="terraform.tfvars.local"
                    print_status "Single account setup resources destroyed"
                fi
                cd - > /dev/null
            else
                print_error "No single account setup configuration found"
            fi
            ;;
        2)
            if [ -f "examples/github-oidc-setup/terraform.tfvars.local" ]; then
                cd "examples/github-oidc-setup"
                print_warning "This will destroy all created IAM roles and resources"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    terraform destroy -var-file="terraform.tfvars.local"
                    print_status "GitHub OIDC setup resources destroyed"
                fi
                cd - > /dev/null
            else
                print_error "No GitHub OIDC setup configuration found"
            fi
            ;;
        3)
            print_info "Cleanup cancelled"
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
}

# Main menu
show_menu() {
    echo ""
    echo "🚀 AWS Bootstrap Role Deployment"
    echo "=================================="
    echo ""
    echo "Choose deployment type:"
    echo "1) Single Account Setup (GitHub Actions + Local Development)"
    echo "2) GitHub OIDC Setup (GitHub Actions Only)"
    echo "3) Cleanup Resources"
    echo "4) Exit"
    echo ""
}

# Main script
main() {
    clear
    print_header "AWS Terraform Bootstrap Role Automation"
    
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Select option (1-4): " choice
        
        case $choice in
            1)
                setup_single_account
                ;;
            2)
                setup_github_oidc
                ;;
            3)
                cleanup_resources
                ;;
            4)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-4."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
