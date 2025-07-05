@echo off
setlocal enabledelayedexpansion

REM =========================================================
REM AWS CRUD Microservices - Terraform Deployment Script (Windows)
REM =========================================================

echo 🚀 AWS CRUD Microservices - Terraform Deployment
echo ==================================================

REM Check if Terraform is installed
terraform --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Terraform is not installed. Please install Terraform first.
    echo    Visit: https://www.terraform.io/downloads.html
    pause
    exit /b 1
)

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS CLI is not installed. Please install AWS CLI first.
    echo    Visit: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS credentials not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed

REM Navigate to terraform directory
cd /d "%~dp0"

REM Create terraform.tfvars if it doesn't exist
if not exist "terraform.tfvars" (
    echo 📝 Creating terraform.tfvars from example...
    copy terraform.tfvars.example terraform.tfvars >nul
    echo ⚠️  Please edit terraform.tfvars with your specific configuration before proceeding.
    echo    Key settings to review:
    echo    - aws_region
    echo    - environment
    echo    - alarm_notification_email
    echo    - allowed_origins
    echo.
    pause
)

REM Get current AWS account info
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
for /f "tokens=*" %%i in ('aws configure get region') do set AWS_REGION=%%i
echo 🔍 Deploying to AWS Account: %AWS_ACCOUNT_ID% in region: %AWS_REGION%

REM Initialize Terraform
echo 🔧 Initializing Terraform...
terraform init

REM Validate configuration
echo ✅ Validating Terraform configuration...
terraform validate

REM Create execution plan
echo 📋 Creating execution plan...
terraform plan -out=tfplan

echo.
echo 📊 Deployment Summary:
echo =====================
echo 🏗️  Infrastructure: Complete AWS serverless stack
echo 📱 Services: Lambda, API Gateway, DynamoDB, Cognito, S3, SNS, SQS, CloudWatch
echo 💰 Est. Cost: $25-75/month for moderate usage
echo 🕐 Deploy Time: ~5-10 minutes
echo.

set /p REPLY="🚀 Ready to deploy? (y/N): "
if /i "%REPLY%"=="y" (
    echo 🚀 Deploying infrastructure...
    terraform apply tfplan
    
    echo.
    echo 🎉 Deployment Complete!
    echo ======================
    echo.
    echo 📍 API Gateway URL:
    terraform output -raw api_gateway_url
    echo.
    echo.
    echo 🔑 Cognito User Pool ID:
    terraform output -raw user_pool_id
    echo.
    echo.
    echo 📱 Cognito Client ID:
    terraform output -raw user_pool_client_id
    echo.
    echo.
    echo 🪣 S3 Bucket:
    terraform output -raw s3_bucket_name
    echo.
    echo.
    echo 📊 All Outputs:
    terraform output
    
    echo.
    echo ✅ Your AWS CRUD Microservices API is now live!
    echo 📚 Check the README.md for API usage examples
    echo 🔍 Monitor your resources in the AWS Console
    echo 💰 Remember to monitor costs in AWS Billing Dashboard
    
) else (
    echo ❌ Deployment cancelled.
    echo 🗑️  Cleaning up plan file...
    del tfplan 2>nul
)

echo.
echo 🔗 Useful commands:
echo    terraform output                 # View all outputs
echo    terraform destroy               # Delete all resources
echo    terraform plan                  # Review changes
echo    terraform apply                 # Apply changes

pause
