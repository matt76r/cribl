#!/bin/bash
# deploy-firehose.sh - Fixed version with proper module path handling

set -e

# Default values
ACTION="plan"
AWS_REGION="us-east-1"
AUTO_APPROVE="false"

# Function to get proper module path
get_module_path() {
    local current_dir="$(pwd)"
    local module_dir="modules/firehose"
    
    # Check if we're in Windows/WSL environment
    if [[ "$current_dir" =~ ^/[c-z]/ ]] || [[ "$current_dir" =~ ^/mnt/[c-z]/ ]]; then
        # WSL environment - use relative path
        echo "./${module_dir}"
    elif [[ "$current_dir" =~ ^/[A-Z]:/ ]]; then
        # Git Bash on Windows - use relative path
        echo "./${module_dir}"
    else
        # Linux/Mac - can use absolute or relative
        if [[ -d "${current_dir}/${module_dir}" ]]; then
            echo "./${module_dir}"
        else
            echo "${current_dir}/${module_dir}"
        fi
    fi
}

# Function to show usage
show_usage() {
    cat << 'USAGE'
Deploy AWS Kinesis Firehose with dynamic parameters

USAGE: ./deploy-firehose.sh -p PROJECT -l LOG_TYPE -d DESTINATION -e ENVIRONMENT [OPTIONS]

REQUIRED:
  -p, --project PROJECT_NAME        Project name (e.g., webapp, security)
  -l, --log LOG_TYPE               Log type (e.g., application, api, audit)
  -d, --destination DESTINATION    Destination (e.g., s3, cribl)
  -e, --environment ENVIRONMENT    Environment (e.g., dev, staging, prod)

OPTIONS:
  -a, --action ACTION              Terraform action: plan, apply, destroy (default: plan)
  -r, --region REGION              AWS region (default: us-east-1)
  --auto-approve                   Auto-approve terraform apply/destroy
  --cribl-url URL                  Cribl Cloud endpoint URL
  --cribl-client-id ID             Cribl Cloud client ID
  --cribl-client-secret SECRET     Cribl Cloud client secret
  -h, --help                       Show this help

EXAMPLES:
  # Plan deployment
  ./deploy-firehose.sh -p webapp -l application -d s3 -e dev

  # Deploy to production
  ./deploy-firehose.sh -p webapp -l api -d s3 -e prod -a apply --auto-approve

  # Deploy with Cribl
  ./deploy-firehose.sh -p security -l audit -d cribl -e prod \
    --cribl-url "https://in.cribl.cloud/sources/http/abc123" \
    --cribl-client-id "client123" \
    --cribl-client-secret "secret456" \
    -a apply

  # Destroy resources
  ./deploy-firehose.sh -p webapp -l application -d s3 -e dev -a destroy
USAGE
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -l|--log)
            LOG_NAME="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        --auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        --cribl-url)
            CRIBL_URL="$2"
            shift 2
            ;;
        --cribl-client-id)
            CRIBL_CLIENT_ID="$2"
            shift 2
            ;;
        --cribl-client-secret)
            CRIBL_CLIENT_SECRET="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_NAME" || -z "$LOG_NAME" || -z "$DESTINATION_NAME" || -z "$ENVIRONMENT" ]]; then
    echo "❌ Missing required parameters!"
    show_usage
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "❌ Invalid action: $ACTION"
    exit 1
fi

# Check if module exists
MODULE_PATH=$(get_module_path)
if [[ ! -d "modules/firehose" ]]; then
    echo "❌ Module not found at: modules/firehose"
    echo "📁 Current directory: $(pwd)"
    echo "📁 Looking for: $(pwd)/modules/firehose"
    echo ""
    echo "💡 Make sure you're running this script from the project root directory"
    echo "   Project structure should be:"
    echo "   📁 project-root/"
    echo "   ├── 📁 modules/"
    echo "   │   └── 📁 firehose/"
    echo "   │       ├── main.tf"
    echo "   │       ├── variables.tf"
    echo "   │       └── outputs.tf"
    echo "   └── 📄 deploy-firehose.sh"
    exit 1
fi

# Create working directory
WORK_DIR="/tmp/terraform-firehose-${PROJECT_NAME}-${LOG_NAME}-${DESTINATION_NAME}-${ENVIRONMENT}-$$"
mkdir -p "$WORK_DIR"

echo "🚀 Deploying: $PROJECT_NAME-$LOG_NAME-$DESTINATION_NAME-$ENVIRONMENT"
echo "📁 Working in: $WORK_DIR"
echo "📦 Module path: $MODULE_PATH"

# Create Terraform configuration
cat > "$WORK_DIR/main.tf" << TFEOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "$AWS_REGION"
}

module "firehose" {
  source = "$MODULE_PATH"
  
  project_name     = "$PROJECT_NAME"
  log_name         = "$LOG_NAME"
  destination_name = "$DESTINATION_NAME"
  environment      = "$ENVIRONMENT"
  
$(if [[ -n "$CRIBL_URL" ]]; then
cat << CRIBLEOF
  cribl_endpoint_url  = "$CRIBL_URL"
  cribl_client_id     = "$CRIBL_CLIENT_ID"
  cribl_client_secret = "$CRIBL_CLIENT_SECRET"
CRIBLEOF
fi)
  
  tags = {
    DeployedBy    = "deploy-firehose-script"
    DeployedAt    = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    SourceScript  = "deploy-firehose.sh"
  }
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.firehose.s3_bucket_name
}

output "stream_name" {
  description = "Firehose delivery stream name"
  value       = module.firehose.firehose_delivery_stream_name
}

output "stream_arn" {
  description = "Firehose delivery stream ARN"
  value       = module.firehose.firehose_delivery_stream_arn
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = module.firehose.firehose_role_arn
}
TFEOF

# Execute Terraform
cd "$WORK_DIR"

echo "🔧 Initializing Terraform..."
terraform init -input=false

case "$ACTION" in
    "plan")
        echo "📋 Running Terraform plan..."
        terraform plan -input=false
        ;;
    "apply")
        echo "🚀 Running Terraform apply..."
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            terraform apply -auto-approve -input=false
        else
            terraform apply -input=false
        fi
        echo ""
        echo "✅ Deployment successful!"
        echo "📊 Resource details:"
        terraform output
        ;;
    "destroy")
        echo "💥 Running Terraform destroy..."
        if [[ "$AUTO_APPROVE" == "true" ]]; then
            terraform destroy -auto-approve -input=false
        else
            terraform destroy -input=false
        fi
        echo "✅ Resources destroyed!"
        ;;
esac

echo ""
echo "📁 Terraform files saved in: $WORK_DIR"
echo "🔍 To inspect: cd $WORK_DIR && terraform show"
