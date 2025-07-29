# Terraform AWS Bootstrap Role Automation
# 
# This Makefile provides easy commands to deploy the IAM bootstrap roles
# for secure Terraform deployments via GitHub Actions and local development.
#
# RECOMMENDATION: Use the automated bootstrap scripts for easier setup:
# - Windows: bootstrap-windows.ps1
# - Linux/macOS: bootstrap-linux.sh

.PHONY: help bootstrap setup-single setup-github clean format validate

# Detect operating system
UNAME_S := $(shell uname -s 2>/dev/null || echo "Windows")
ifeq ($(UNAME_S),Linux)
    OS_TYPE = linux
endif
ifeq ($(UNAME_S),Darwin)
    OS_TYPE = macos
endif
ifneq (,$(findstring CYGWIN,$(UNAME_S)))
    OS_TYPE = windows
endif
ifneq (,$(findstring MINGW,$(UNAME_S)))
    OS_TYPE = windows
endif
ifeq ($(UNAME_S),Windows)
    OS_TYPE = windows
endif
ifndef OS_TYPE
    OS_TYPE = windows
endif

# Default target
help:
	@echo "🚀 Terraform AWS Bootstrap Role Automation"
	@echo ""
	@echo "🎯 RECOMMENDED: Use automated bootstrap scripts:"
ifeq ($(OS_TYPE),windows)
	@echo "   Windows: .\\scripts\\bootstrap-windows.ps1 -AccountId \"123456789012\" -ProjectName \"my-project\""
else
	@echo "   Linux/macOS: ./scripts/bootstrap-linux.sh -a 123456789012 -p my-project"
endif
	@echo ""
	@echo "Available make targets:"
	@echo "  bootstrap      - Run the appropriate bootstrap script for your OS"
	@echo "  setup-single   - Deploy roles for GitHub and local access"
	@echo "  setup-github   - Deploy roles for GitHub OIDC only"
	@echo "  clean          - Clean up all created resources"
	@echo "  format         - Format all Terraform files"
	@echo "  validate       - Validate Terraform configuration"
	@echo ""
	@echo "Before using make commands:"
	@echo "  1. Edit terraform.tfvars in your chosen example directory"
	@echo "  2. Ensure you have AWS admin credentials configured"

# Cross-platform bootstrap command
bootstrap:
	@echo "🔧 Detecting operating system: $(OS_TYPE)"
ifeq ($(OS_TYPE),windows)
	@echo "📝 For Windows, please run:"
	@echo "   .\\scripts\\bootstrap-windows.ps1 -AccountId \"YOUR-ACCOUNT-ID\" -ProjectName \"YOUR-PROJECT\""
	@echo ""
	@echo "Example:"
	@echo "   .\\scripts\\bootstrap-windows.ps1 -AccountId \"123456789012\" -ProjectName \"my-project\" -Environment \"dev\""
else
	@echo "🚀 Running Linux/macOS bootstrap script..."
	@echo "Usage: make bootstrap ACCOUNT_ID=123456789012 PROJECT_NAME=my-project [ENVIRONMENT=dev]"
	@echo ""
	@if [ -z "$(ACCOUNT_ID)" ] || [ -z "$(PROJECT_NAME)" ]; then \
		echo "❌ Please provide ACCOUNT_ID and PROJECT_NAME:"; \
		echo "   make bootstrap ACCOUNT_ID=123456789012 PROJECT_NAME=my-project"; \
		exit 1; \
	fi
	@./scripts/bootstrap-linux.sh -a "$(ACCOUNT_ID)" -p "$(PROJECT_NAME)" -e "$(or $(ENVIRONMENT),dev)"
endif

# Setup for GitHub and local access (supports both GitHub Actions and local development)
setup-single:
	@echo "🔧 Setting up IAM roles for GitHub and local access deployment..."
	@echo "📁 Working directory: examples/github-and-local-access"
	@if [ ! -f examples/github-and-local-access/terraform.tfvars ]; then \
		echo "❌ terraform.tfvars not found!"; \
		echo "📝 Please configure: examples/github-and-local-access/terraform.tfvars"; \
		exit 1; \
	fi
	@cd examples/github-and-local-access && terraform init
	@cd examples/github-and-local-access && terraform plan
	@echo "🚀 Deploying roles..."
	@cd examples/github-and-local-access && terraform apply -auto-approve
	@echo "✅ Setup complete! Check the output above for next steps."

# Setup for GitHub OIDC only
setup-github:
	@echo "🔧 Setting up IAM roles for GitHub OIDC deployment..."
	@echo "📁 Working directory: examples/github-oidc-setup"
	@if [ ! -f examples/github-oidc-setup/terraform.tfvars ]; then \
		echo "❌ terraform.tfvars not found!"; \
		echo "📝 Please configure: examples/github-oidc-setup/terraform.tfvars"; \
		exit 1; \
	fi
	@cd examples/github-oidc-setup && terraform init
	@cd examples/github-oidc-setup && terraform plan
	@echo "🚀 Deploying roles..."
	@cd examples/github-oidc-setup && terraform apply -auto-approve
	@echo "✅ Setup complete! Check the output above for GitHub Actions workflow."

# Clean up resources
clean:
	@echo "🧹 Cleaning up resources..."
	@echo "Choose which setup to clean:"
	@echo "1) GitHub and local access setup"
	@echo "2) GitHub OIDC setup"
	@read -p "Enter choice (1 or 2): " choice; \
	case $$choice in \
		1) cd examples/github-and-local-access && terraform destroy ;; \
		2) cd examples/github-oidc-setup && terraform destroy ;; \
		*) echo "❌ Invalid choice" && exit 1 ;; \
	esac
	@echo "🗑️  Resources cleaned up!"

# Format all Terraform files
format:
	@echo "📝 Formatting Terraform files..."
	@terraform fmt -recursive .
	@echo "✅ Formatting complete!"

# Validate Terraform configuration
validate:
	@echo "🔍 Validating Terraform configuration..."
	@cd modules/iam-bootstrap && terraform init -backend=false && terraform validate
	@cd examples/github-and-local-access && terraform init -backend=false && terraform validate
	@cd examples/github-oidc-setup && terraform init -backend=false && terraform validate
	@echo "✅ Validation complete!"

# Quick development helpers
dev-init:
	@echo "🛠️  Development setup..."
	@terraform fmt -recursive .
	@echo "✅ Development environment ready!"
# Quick development helpers
dev-init:
	@echo "�️  Development setup..."
	@terraform fmt -recursive .
	@echo "✅ Development environment ready!"
