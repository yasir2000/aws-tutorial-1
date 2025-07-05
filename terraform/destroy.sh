#!/bin/bash

# =========================================================
# AWS CRUD Microservices - Terraform Destroy Script
# =========================================================

set -e

echo "🗑️  AWS CRUD Microservices - Infrastructure Cleanup"
echo "================================================="

# Navigate to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "❌ No Terraform state found. Nothing to destroy."
    exit 1
fi

# Show what will be destroyed
echo "🔍 Reviewing resources to be destroyed..."
terraform plan -destroy

echo ""
echo "⚠️  WARNING: This will permanently delete ALL AWS resources!"
echo "📊 Resources to be deleted:"
echo "   - All Lambda functions"
echo "   - API Gateway REST API"
echo "   - DynamoDB tables (with all data)"
echo "   - S3 bucket (with all files)"
echo "   - Cognito User Pool (with all users)"
echo "   - SNS topics and SQS queues"
echo "   - CloudWatch logs and alarms"
echo "   - IAM roles and policies"
echo ""
echo "💾 Data Loss Warning:"
echo "   - All user accounts will be deleted"
echo "   - All stored files will be deleted"
echo "   - All database records will be deleted"
echo "   - This action cannot be undone!"
echo ""

read -p "🚨 Are you ABSOLUTELY sure you want to destroy everything? Type 'YES' to confirm: " -r
if [[ $REPLY == "YES" ]]; then
    echo "🗑️  Starting destruction process..."
    
    # Check for DynamoDB deletion protection
    echo "🔓 Checking for deletion protection..."
    
    # Show final confirmation
    echo ""
    read -p "🚨 Last chance! Type 'DESTROY' to proceed: " -r
    if [[ $REPLY == "DESTROY" ]]; then
        echo "💥 Destroying infrastructure..."
        terraform destroy -auto-approve
        
        echo ""
        echo "✅ All resources have been destroyed!"
        echo "💰 AWS charges have stopped"
        echo "🗑️  Terraform state files remain for reference"
        echo ""
        echo "🧹 To completely clean up:"
        echo "   rm -rf .terraform/"
        echo "   rm terraform.tfstate*"
        echo "   rm tfplan"
    else
        echo "❌ Destruction cancelled. Invalid confirmation."
    fi
else
    echo "❌ Destruction cancelled. Resources remain active."
fi

echo ""
echo "🔗 If you need to redeploy:"
echo "   ./deploy.sh                     # Run deployment script"
echo "   terraform plan                  # Review planned changes"
echo "   terraform apply                 # Apply infrastructure"
