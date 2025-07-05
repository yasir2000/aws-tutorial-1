# Terraform Deployment Guide

This directory contains the complete Terraform configuration to deploy the AWS CRUD Microservices project to production using all 8 major AWS services.

## 🏗️ Infrastructure Overview

The Terraform configuration deploys:

- **22 Lambda Functions** (Auth, Users, Products, Orders, Files, Notifications)
- **API Gateway REST API** with full CRUD endpoints
- **3 DynamoDB Tables** (Users, Products, Orders)
- **Cognito User Pool & Client** for authentication
- **S3 Bucket** for file storage with encryption and lifecycle policies
- **SNS Topic** for event publishing
- **SQS Queue** with Dead Letter Queue for notifications
- **CloudWatch** log groups, dashboard, and alarms
- **IAM Roles & Policies** with least privilege access

## 📋 Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **Node.js project** with all handlers and utilities in place
4. **AWS Account** with permissions to create all resources

## 🚀 Quick Start

### 1. Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the file with your specific configuration
vim terraform.tfvars
```

### 2. Initialize Terraform

```bash
# Initialize Terraform with required providers
terraform init

# Optional: Validate configuration
terraform validate
```

### 3. Plan Deployment

```bash
# Review what will be created
terraform plan

# Save plan for review
terraform plan -out=tfplan
```

### 4. Deploy Infrastructure

```bash
# Apply the configuration
terraform apply

# Or apply the saved plan
terraform apply tfplan
```

### 5. Get Outputs

```bash
# Display all outputs
terraform output

# Get specific output (e.g., API URL)
terraform output api_gateway_url
```

## 📊 Key Configuration Options

### Environment Types
- `dev` - Development environment with lower costs
- `staging` - Staging environment for testing
- `production` - Production environment with full features

### Cost Optimization
- **DynamoDB**: Use `PAY_PER_REQUEST` for variable workloads, `PROVISIONED` for predictable traffic
- **Lambda**: Set appropriate memory and timeout values
- **S3**: Enable lifecycle policies to reduce storage costs
- **CloudWatch**: Adjust log retention periods

### Security Features
- **Cognito**: Password policies and MFA support
- **S3**: Server-side encryption and CORS configuration
- **API Gateway**: Rate limiting and request validation
- **IAM**: Least privilege access policies

## 🔍 Monitoring & Alerting

### CloudWatch Dashboard
Automatically created dashboard includes:
- Lambda function metrics (duration, errors, invocations)
- DynamoDB capacity consumption
- API Gateway latency and error rates
- S3 bucket metrics

### Alarms
Configurable alarms for:
- Lambda error rates
- API Gateway latency
- DynamoDB throttling
- S3 request errors

### Log Aggregation
Centralized logging for:
- API Gateway access logs
- Lambda function logs
- Application-level logging

## 📱 API Endpoints

After deployment, your API will be available at:
```
https://{api-id}.execute-api.{region}.amazonaws.com/{environment}/
```

### Authentication Endpoints
- `POST /auth/signup` - User registration
- `POST /auth/signin` - User login
- `POST /auth/confirm` - Email confirmation
- `GET /auth/profile` - Get user profile (authenticated)

### CRUD Endpoints
- **Users**: `/users` (POST), `/users/{id}` (GET, PUT, DELETE)
- **Products**: `/products` (GET, POST), `/products/{id}` (GET, PUT, DELETE)
- **Orders**: `/orders` (GET, POST)

### File Management
- `GET /files` - List files
- `POST /files/upload` - Upload file
- `POST /files/upload-url` - Get presigned upload URL
- `GET /files/{filename}` - Download file
- `DELETE /files/{filename}` - Delete file

## 💰 Cost Estimation

### Monthly Costs (approximate)
- **Lambda**: $0-10 (based on requests)
- **API Gateway**: $3.50 per million requests
- **DynamoDB**: $0-25 (PAY_PER_REQUEST)
- **S3**: $0.023 per GB stored
- **Cognito**: $0.0055 per MAU (Monthly Active User)
- **SNS/SQS**: $0.50 per million requests
- **CloudWatch**: $0.50 per GB ingested

### Cost Optimization Tips
1. Use Lambda ARM64 for 20% cost savings
2. Set appropriate DynamoDB billing mode
3. Configure S3 lifecycle policies
4. Monitor CloudWatch log retention
5. Use reserved capacity for predictable workloads

## 🔧 Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Ensure IAM user has required permissions
   aws iam list-attached-user-policies --user-name your-username
   ```

2. **Lambda Package Too Large**
   ```bash
   # Check package size
   ls -lh lambda_deployment.zip
   
   # Exclude unnecessary files in main.tf archive_file
   ```

3. **API Gateway 5XX Errors**
   ```bash
   # Check Lambda logs
   aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/crud-microservices"
   
   # Check specific function logs
   aws logs get-log-events --log-group-name "/aws/lambda/function-name"
   ```

4. **DynamoDB Throttling**
   ```bash
   # Check metrics
   aws cloudwatch get-metric-statistics --namespace AWS/DynamoDB --metric-name ConsumedReadCapacityUnits
   
   # Consider switching to PAY_PER_REQUEST or increasing capacity
   ```

### Debugging Commands

```bash
# View Terraform state
terraform show

# List all resources
terraform state list

# Get specific resource details
terraform state show aws_lambda_function.signup

# Check for configuration drift
terraform plan -detailed-exitcode
```

## 🔄 Updates & Maintenance

### Updating Lambda Code
```bash
# Terraform will detect code changes and redeploy
terraform apply

# Force Lambda update
terraform taint aws_lambda_function.signup
terraform apply
```

### Scaling Considerations
- Monitor Lambda concurrent executions
- Watch DynamoDB capacity metrics
- Set up auto-scaling for high-traffic periods
- Consider Lambda reserved concurrency for critical functions

### Backup Strategy
- DynamoDB point-in-time recovery (enabled by default)
- S3 versioning and cross-region replication
- Terraform state backup in S3 backend
- Regular exports of Cognito user pool

## 🔒 Security Best Practices

1. **Enable all security features** in terraform.tfvars
2. **Use HTTPS only** for API Gateway
3. **Implement proper CORS** policies
4. **Regular security audits** using AWS Config
5. **Enable CloudTrail** for audit logging
6. **Use AWS WAF** for production workloads
7. **Implement proper VPC** for sensitive workloads

## 📚 Additional Resources

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [API Gateway Security](https://docs.aws.amazon.com/apigateway/latest/developerguide/security.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🆘 Support

For issues related to:
- **Terraform configuration**: Check Terraform documentation
- **AWS services**: Check AWS documentation and support
- **Application code**: Review handler implementations
- **Performance**: Monitor CloudWatch metrics and logs
