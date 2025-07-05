#!/bin/bash

# =========================================================
# AWS CRUD Microservices - Terraform Deployment Script
# =========================================================

set -e

echo "🚀 AWS CRUD Microservices - Terraform Deployment"
echo "=================================================="

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    echo "   Visit: https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    echo "   Visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Navigate to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please edit terraform.tfvars with your specific configuration before proceeding."
    echo "   Key settings to review:"
    echo "   - aws_region"
    echo "   - environment" 
    echo "   - alarm_notification_email"
    echo "   - allowed_origins"
    echo ""
    read -p "Press Enter to continue after editing terraform.tfvars, or Ctrl+C to exit..."
fi

# Get current AWS account info
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
echo "🔍 Deploying to AWS Account: $AWS_ACCOUNT_ID in region: $AWS_REGION"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Create execution plan
echo "📋 Creating execution plan..."
terraform plan -out=tfplan

echo ""
echo "📊 Deployment Summary:"
echo "====================="
echo "🏗️  Infrastructure: Complete AWS serverless stack"
echo "📱 Services: Lambda, API Gateway, DynamoDB, Cognito, S3, SNS, SQS, CloudWatch"
echo "💰 Est. Cost: $25-75/month for moderate usage"
echo "🕐 Deploy Time: ~5-10 minutes"
echo ""

# Confirm deployment
read -p "🚀 Ready to deploy? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying infrastructure..."
    terraform apply tfplan
    
    # Display outputs
    echo ""
    echo "🎉 Deployment Complete!"
    echo "======================"
    echo ""
    echo "📍 API Gateway URL:"
    terraform output -raw api_gateway_url
    echo ""
    echo ""
    echo "🔑 Cognito User Pool ID:"
    terraform output -raw user_pool_id
    echo ""
    echo ""
    echo "📱 Cognito Client ID:"
    terraform output -raw user_pool_client_id
    echo ""
    echo ""
    echo "🪣 S3 Bucket:"
    terraform output -raw s3_bucket_name
    echo ""
    echo ""
    echo "📊 All Outputs:"
    terraform output
    
    echo ""
    echo "✅ Your AWS CRUD Microservices API is now live!"
    echo "📚 Check the README.md for API usage examples"
    echo "🔍 Monitor your resources in the AWS Console"
    echo "💰 Remember to monitor costs in AWS Billing Dashboard"
    
else
    echo "❌ Deployment cancelled."
    echo "🗑️  Cleaning up plan file..."
    rm -f tfplan
fi

echo ""
echo "🔗 Useful commands:"
echo "   terraform output                 # View all outputs"
echo "   terraform destroy               # Delete all resources"
echo "   terraform plan                  # Review changes"
echo "   terraform apply                 # Apply changes"
