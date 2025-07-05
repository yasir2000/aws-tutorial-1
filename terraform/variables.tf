# =========================================================
# Variables for AWS CRUD Microservices Infrastructure
# =========================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format xx-xxxx-x (e.g., us-east-1)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "crud-microservices"
}

# =========================================================
# Lambda Configuration Variables
# =========================================================

variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Memory allocation for Lambda functions in MB"
  type        = number
  default     = 512
}

variable "lambda_architecture" {
  description = "Architecture for Lambda functions"
  type        = string
  default     = "x86_64"
  
  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_architecture)
    error_message = "Lambda architecture must be either x86_64 or arm64."
  }
}

# =========================================================
# DynamoDB Configuration Variables
# =========================================================

variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB tables"
  type        = string
  default     = "PAY_PER_REQUEST"
  
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "Read capacity units for DynamoDB tables (when using PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units for DynamoDB tables (when using PROVISIONED billing)"
  type        = number
  default     = 5
}

variable "enable_dynamodb_deletion_protection" {
  description = "Enable deletion protection for DynamoDB tables"
  type        = bool
  default     = true
}

# =========================================================
# S3 Configuration Variables
# =========================================================

variable "s3_bucket_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_encryption" {
  description = "Enable server-side encryption for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_enabled" {
  description = "Enable lifecycle management for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_expiration_days" {
  description = "Days after which objects expire in S3 bucket"
  type        = number
  default     = 365
}

# =========================================================
# Cognito Configuration Variables
# =========================================================

variable "cognito_password_minimum_length" {
  description = "Minimum password length for Cognito users"
  type        = number
  default     = 8
}

variable "cognito_password_require_uppercase" {
  description = "Require uppercase characters in Cognito passwords"
  type        = bool
  default     = true
}

variable "cognito_password_require_lowercase" {
  description = "Require lowercase characters in Cognito passwords"
  type        = bool
  default     = true
}

variable "cognito_password_require_numbers" {
  description = "Require numbers in Cognito passwords"
  type        = bool
  default     = true
}

variable "cognito_password_require_symbols" {
  description = "Require symbols in Cognito passwords"
  type        = bool
  default     = true
}

variable "cognito_token_validity_hours" {
  description = "Token validity in hours for Cognito"
  type        = number
  default     = 24
}

variable "cognito_refresh_token_validity_days" {
  description = "Refresh token validity in days for Cognito"
  type        = number
  default     = 30
}

# =========================================================
# API Gateway Configuration Variables
# =========================================================

variable "api_gateway_throttling_rate_limit" {
  description = "Rate limit for API Gateway throttling"
  type        = number
  default     = 1000
}

variable "api_gateway_throttling_burst_limit" {
  description = "Burst limit for API Gateway throttling"
  type        = number
  default     = 2000
}

variable "enable_api_gateway_logging" {
  description = "Enable logging for API Gateway"
  type        = bool
  default     = true
}

variable "api_gateway_log_level" {
  description = "Log level for API Gateway"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.api_gateway_log_level)
    error_message = "API Gateway log level must be one of: OFF, ERROR, INFO."
  }
}

# =========================================================
# CloudWatch Configuration Variables
# =========================================================

variable "cloudwatch_log_retention_days" {
  description = "Retention period for CloudWatch logs in days"
  type        = number
  default     = 14
}

variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard creation"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

# =========================================================
# SNS & SQS Configuration Variables
# =========================================================

variable "sqs_visibility_timeout_seconds" {
  description = "Visibility timeout for SQS queue in seconds"
  type        = number
  default     = 300
}

variable "sqs_message_retention_seconds" {
  description = "Message retention period for SQS queue in seconds"
  type        = number
  default     = 1209600  # 14 days
}

variable "sqs_receive_wait_time_seconds" {
  description = "Receive wait time for SQS queue in seconds"
  type        = number
  default     = 20
}

variable "enable_sqs_dead_letter_queue" {
  description = "Enable dead letter queue for SQS"
  type        = bool
  default     = true
}

variable "sqs_max_receive_count" {
  description = "Maximum receive count before message goes to DLQ"
  type        = number
  default     = 3
}

# =========================================================
# Monitoring and Alerting Variables
# =========================================================

variable "alarm_notification_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "enable_error_rate_alarm" {
  description = "Enable error rate alarms"
  type        = bool
  default     = true
}

variable "error_rate_threshold" {
  description = "Error rate threshold percentage for alarms"
  type        = number
  default     = 5
}

variable "enable_latency_alarm" {
  description = "Enable latency alarms"
  type        = bool
  default     = true
}

variable "latency_threshold_ms" {
  description = "Latency threshold in milliseconds for alarms"
  type        = number
  default     = 3000
}

# =========================================================
# Security Variables
# =========================================================

variable "enable_waf" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = false  # Disabled by default due to additional costs
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "enable_vpc" {
  description = "Deploy Lambda functions in VPC for enhanced security"
  type        = bool
  default     = false  # Disabled by default for simplicity
}

# =========================================================
# Backup and Disaster Recovery Variables
# =========================================================

variable "enable_dynamodb_backups" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

variable "enable_s3_cross_region_replication" {
  description = "Enable cross-region replication for S3 bucket"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

# =========================================================
# Cost Optimization Variables
# =========================================================

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency for Lambda functions (0 = unreserved)"
  type        = number
  default     = 0
}
