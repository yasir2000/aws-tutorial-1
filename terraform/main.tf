terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
# DynamoDB Tables
resource "aws_dynamodb_table" "users" {
  name           = "crud-microservices-users-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "products" {
  name           = "crud-microservices-products-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_dynamodb_table" "orders" {
  name           = "crud-microservices-orders-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

# SNS Topic
resource "aws_sns_topic" "events" {
  name = "crud-microservices-events-${var.environment}"
}

# SQS Queue
resource "aws_sqs_queue" "notifications" {
  name                      = "crud-microservices-notifications-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# SNS to SQS Subscription
resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notifications.arn
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "crud-microservices-${var.environment}"

  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "crud-microservices-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH"
  ]

  generate_secret = false
}

# Outputs
output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.events.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.notifications.url
}

output "dynamodb_users_table_name" {
  value = aws_dynamodb_table.users.name
}