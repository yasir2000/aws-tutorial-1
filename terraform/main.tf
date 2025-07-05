# =========================================================
# AWS CRUD Microservices - Complete Terraform Infrastructure
# Deploys all 8 AWS services for production environment
# =========================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-crud-microservices"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# =========================================================
# Local Values
# =========================================================
locals {
  service_name = "crud-microservices"
  common_tags = {
    Project     = "aws-crud-microservices"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  
  # Lambda function names
  lambda_functions = {
    signup           = "signup"
    signin           = "signin"
    confirm_signup   = "confirmSignup"
    get_profile     = "getProfile"
    create_user     = "createUser"
    get_user        = "getUser"
    update_user     = "updateUser"
    delete_user     = "deleteUser"
    create_product  = "createProduct"
    get_products    = "getProducts"
    get_product     = "getProduct"
    update_product  = "updateProduct"
    delete_product  = "deleteProduct"
    create_order    = "createOrder"
    get_orders      = "getOrders"
    upload_file     = "uploadFile"
    get_file        = "getFile"
    list_files      = "listFiles"
    delete_file     = "deleteFile"
    generate_upload_url = "generateUploadUrl"
    process_notification = "processNotification"
  }
}
resource "aws_dynamodb_table" "users" {
  name           = "${local.service_name}-users-${var.environment}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id"
  deletion_protection_enabled = var.enable_dynamodb_deletion_protection

  attribute {
    name = "id"
    type = "S"
  }

  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  point_in_time_recovery {
    enabled = var.enable_dynamodb_backups
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-users-${var.environment}"
    Type = "DynamoDB"
  })
}

resource "aws_dynamodb_table" "products" {
  name           = "${local.service_name}-products-${var.environment}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id"
  deletion_protection_enabled = var.enable_dynamodb_deletion_protection

  attribute {
    name = "id"
    type = "S"
  }

  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  point_in_time_recovery {
    enabled = var.enable_dynamodb_backups
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-products-${var.environment}"
    Type = "DynamoDB"
  })
}

resource "aws_dynamodb_table" "orders" {
  name           = "${local.service_name}-orders-${var.environment}"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id"
  deletion_protection_enabled = var.enable_dynamodb_deletion_protection

  attribute {
    name = "id"
    type = "S"
  }

  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  point_in_time_recovery {
    enabled = var.enable_dynamodb_backups
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-orders-${var.environment}"
    Type = "DynamoDB"
  })
}

# =========================================================
# S3 Bucket for File Storage
# =========================================================

resource "aws_s3_bucket" "files" {
  bucket = "${local.service_name}-files-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-files-${var.environment}"
    Type = "S3"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "files" {
  count  = var.s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.files.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  count  = var.s3_bucket_encryption ? 1 : 0
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "files" {
  count  = var.s3_lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.files.id

  rule {
    id     = "expire_old_objects"
    status = "Enabled"

    expiration {
      days = var.s3_lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# =========================================================
# SNS Topic for Events
# =========================================================

resource "aws_sns_topic" "events" {
  name = "${local.service_name}-events-${var.environment}"

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-events-${var.environment}"
    Type = "SNS"
  })
}

# =========================================================
# SQS Queue for Notifications
# =========================================================

resource "aws_sqs_queue" "notifications" {
  name                      = "${local.service_name}-notifications-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  redrive_policy = var.enable_sqs_dead_letter_queue ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq[0].arn
    maxReceiveCount     = var.sqs_max_receive_count
  }) : null

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-notifications-${var.environment}"
    Type = "SQS"
  })
}

resource "aws_sqs_queue" "notifications_dlq" {
  count = var.enable_sqs_dead_letter_queue ? 1 : 0
  name  = "${local.service_name}-notifications-dlq-${var.environment}"

  message_retention_seconds = 1209600  # 14 days

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-notifications-dlq-${var.environment}"
    Type = "SQS-DLQ"
  })
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.events.arn
          }
        }
      }
    ]
  })
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

# =========================================================
# IAM Roles and Policies
# =========================================================

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.service_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-lambda-role-${var.environment}"
    Type = "IAM"
  })
}

# IAM Policy for Lambda functions
resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.service_name}-lambda-policy-${var.environment}"
  description = "IAM policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.products.arn,
          aws_dynamodb_table.orders.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.notifications.arn,
          var.enable_sqs_dead_letter_queue ? aws_sqs_queue.notifications_dlq[0].arn : ""
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.files.arn,
          "${aws_s3_bucket.files.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDeleteUser"
        ]
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# =========================================================
# Lambda Functions
# =========================================================

# Create deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../"
  output_path = "${path.module}/lambda_deployment.zip"
  excludes = [
    "terraform/*",
    ".git/*",
    "node_modules/*",
    "*.md",
    ".serverless/*",
    "docker-compose.yml"
  ]
}

# Authentication Lambda Functions
resource "aws_lambda_function" "signup" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-signup-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/auth.signup"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-signup-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "signin" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-signin-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/auth.signin"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-signin-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "confirm_signup" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-confirm-signup-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/auth.confirmSignup"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-confirm-signup-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_profile" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-profile-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/auth.getProfile"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-profile-${var.environment}"
    Type = "Lambda"
  })
}

# User Management Lambda Functions
resource "aws_lambda_function" "create_user" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-create-user-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/users.create"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-create-user-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_user" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-user-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/users.get"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-user-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "update_user" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-update-user-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/users.update"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-update-user-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "delete_user" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-delete-user-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/users.delete"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-delete-user-${var.environment}"
    Type = "Lambda"
  })
}

# Product Management Lambda Functions
resource "aws_lambda_function" "create_product" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-create-product-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/products.create"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-create-product-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_products" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-products-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/products.getAll"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-products-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_product" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-product-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/products.get"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-product-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "update_product" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-update-product-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/products.update"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-update-product-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "delete_product" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-delete-product-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/products.delete"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-delete-product-${var.environment}"
    Type = "Lambda"
  })
}

# Order Management Lambda Functions
resource "aws_lambda_function" "create_order" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-create-order-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/orders.create"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-create-order-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_orders" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-orders-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/orders.getAll"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-orders-${var.environment}"
    Type = "Lambda"
  })
}

# File Management Lambda Functions
resource "aws_lambda_function" "upload_file" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-upload-file-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/files.upload"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-upload-file-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "get_file" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-get-file-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/files.getFile"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-get-file-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "list_files" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-list-files-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/files.listFiles"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-list-files-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "delete_file" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-delete-file-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/files.deleteFile"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-delete-file-${var.environment}"
    Type = "Lambda"
  })
}

resource "aws_lambda_function" "generate_upload_url" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-generate-upload-url-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/files.generateUploadUrl"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-generate-upload-url-${var.environment}"
    Type = "Lambda"
  })
}

# Notification Processing Lambda Function
resource "aws_lambda_function" "process_notification" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.service_name}-process-notification-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handlers/notifications.processNotification"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory
  architectures   = [var.lambda_architecture]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      USERS_TABLE           = aws_dynamodb_table.users.name
      PRODUCTS_TABLE        = aws_dynamodb_table.products.name
      ORDERS_TABLE          = aws_dynamodb_table.orders.name
      SNS_TOPIC             = aws_sns_topic.events.arn
      SQS_QUEUE             = aws_sqs_queue.notifications.url
      COGNITO_USER_POOL_ID  = aws_cognito_user_pool.main.id
      COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.main.id
      S3_BUCKET             = aws_s3_bucket.files.bucket
      NODE_ENV              = "production"
      IS_OFFLINE            = "false"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-process-notification-${var.environment}"
    Type = "Lambda"
  })
}

# Event source mapping for SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.process_notification.arn
  batch_size       = 10
  enabled          = true

  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}

# =========================================================
# API Gateway REST API
# =========================================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.service_name}-api-${var.environment}"
  description = "REST API for CRUD Microservices"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-api-${var.environment}"
    Type = "API Gateway"
  })
}

# Cognito User Pool Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name                   = "CognitoAuthorizer"
  rest_api_id           = aws_api_gateway_rest_api.main.id
  type                  = "COGNITO_USER_POOLS"
  provider_arns         = [aws_cognito_user_pool.main.arn]
  identity_source       = "method.request.header.Authorization"
  authorizer_credentials = aws_iam_role.lambda_execution_role.arn
}

# API Gateway Resources and Methods
# Auth resources
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "auth_signup" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "signup"
}

resource "aws_api_gateway_resource" "auth_signin" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "signin"
}

resource "aws_api_gateway_resource" "auth_confirm" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "confirm"
}

resource "aws_api_gateway_resource" "auth_profile" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "profile"
}

# Users resources
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "users_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{id}"
}

# Products resources
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "products_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{id}"
}

# Orders resources
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

# Files resources
resource "aws_api_gateway_resource" "files" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "files"
}

resource "aws_api_gateway_resource" "files_upload" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "files_upload_url" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "upload-url"
}

resource "aws_api_gateway_resource" "files_filename" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "{filename}"
}

# =========================================================
# CloudWatch Log Groups
# =========================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.service_name}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-api-gateway-logs-${var.environment}"
    Type = "CloudWatch"
  })
}

# Lambda function log groups
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${local.service_name}-${each.value}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-${each.value}-logs-${var.environment}"
    Type = "CloudWatch"
  })
}

# =========================================================
# CloudWatch Dashboard (Optional)
# =========================================================

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_cloudwatch_dashboard ? 1 : 0
  dashboard_name = "${local.service_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.signup.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.users.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Metrics"
        }
      }
    ]
  })
}

# =========================================================
# Outputs
# =========================================================

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_domain" {
  description = "Cognito User Pool Domain"
  value       = aws_cognito_user_pool.main.domain
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for events"
  value       = aws_sns_topic.events.arn
}

output "sns_alarms_topic_arn" {
  description = "SNS Topic ARN for alarms"
  value       = var.enable_cloudwatch_alarms && var.alarm_notification_email != "" ? aws_sns_topic.alarms[0].arn : null
}

output "sqs_queue_url" {
  description = "SQS Queue URL for notifications"
  value       = aws_sqs_queue.notifications.url
}

output "sqs_queue_arn" {
  description = "SQS Queue ARN for notifications"
  value       = aws_sqs_queue.notifications.arn
}

output "sqs_dlq_url" {
  description = "SQS Dead Letter Queue URL"
  value       = var.enable_sqs_dead_letter_queue ? aws_sqs_queue.notifications_dlq[0].url : null
}

output "s3_bucket_name" {
  description = "S3 Bucket Name for file storage"
  value       = aws_s3_bucket.files.bucket
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.files.arn
}

output "s3_bucket_domain_name" {
  description = "S3 Bucket Domain Name"
  value       = aws_s3_bucket.files.bucket_domain_name
}

output "dynamodb_table_names" {
  description = "DynamoDB Table Names"
  value = {
    users    = aws_dynamodb_table.users.name
    products = aws_dynamodb_table.products.name
    orders   = aws_dynamodb_table.orders.name
  }
}

output "dynamodb_table_arns" {
  description = "DynamoDB Table ARNs"
  value = {
    users    = aws_dynamodb_table.users.arn
    products = aws_dynamodb_table.products.arn
    orders   = aws_dynamodb_table.orders.arn
  }
}

output "lambda_function_names" {
  description = "Lambda Function Names"
  value = {
    signup               = aws_lambda_function.signup.function_name
    signin               = aws_lambda_function.signin.function_name
    confirm_signup       = aws_lambda_function.confirm_signup.function_name
    get_profile         = aws_lambda_function.get_profile.function_name
    create_user         = aws_lambda_function.create_user.function_name
    get_user            = aws_lambda_function.get_user.function_name
    update_user         = aws_lambda_function.update_user.function_name
    delete_user         = aws_lambda_function.delete_user.function_name
    create_product      = aws_lambda_function.create_product.function_name
    get_products        = aws_lambda_function.get_products.function_name
    get_product         = aws_lambda_function.get_product.function_name
    update_product      = aws_lambda_function.update_product.function_name
    delete_product      = aws_lambda_function.delete_product.function_name
    create_order        = aws_lambda_function.create_order.function_name
    get_orders          = aws_lambda_function.get_orders.function_name
    upload_file         = aws_lambda_function.upload_file.function_name
    get_file           = aws_lambda_function.get_file.function_name
    list_files         = aws_lambda_function.list_files.function_name
    delete_file        = aws_lambda_function.delete_file.function_name
    generate_upload_url = aws_lambda_function.generate_upload_url.function_name
    process_notification = aws_lambda_function.process_notification.function_name
  }
}

output "lambda_function_arns" {
  description = "Lambda Function ARNs"
  value = {
    signup               = aws_lambda_function.signup.arn
    signin               = aws_lambda_function.signin.arn
    confirm_signup       = aws_lambda_function.confirm_signup.arn
    get_profile         = aws_lambda_function.get_profile.arn
    create_user         = aws_lambda_function.create_user.arn
    get_user            = aws_lambda_function.get_user.arn
    update_user         = aws_lambda_function.update_user.arn
    delete_user         = aws_lambda_function.delete_user.arn
    create_product      = aws_lambda_function.create_product.arn
    get_products        = aws_lambda_function.get_products.arn
    get_product         = aws_lambda_function.get_product.arn
    update_product      = aws_lambda_function.update_product.arn
    delete_product      = aws_lambda_function.delete_product.arn
    create_order        = aws_lambda_function.create_order.arn
    get_orders          = aws_lambda_function.get_orders.arn
    upload_file         = aws_lambda_function.upload_file.arn
    get_file           = aws_lambda_function.get_file.arn
    list_files         = aws_lambda_function.list_files.arn
    delete_file        = aws_lambda_function.delete_file.arn
    generate_upload_url = aws_lambda_function.generate_upload_url.arn
    process_notification = aws_lambda_function.process_notification.arn
  }
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch Log Group Names"
  value = {
    api_gateway = aws_cloudwatch_log_group.api_gateway.name
    lambda_logs = { for k, v in aws_cloudwatch_log_group.lambda_logs : k => v.name }
  }
}

output "iam_role_arn" {
  description = "IAM Role ARN for Lambda functions"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Summary output for easy reference
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    api_url        = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
    cognito_pool   = aws_cognito_user_pool.main.id
    s3_bucket      = aws_s3_bucket.files.bucket
    lambda_count   = length(local.lambda_functions)
    region         = var.aws_region
    environment    = var.environment
  }
}

# =========================================================
# API Gateway Methods and Integrations
# =========================================================

# Auth signup POST method
resource "aws_api_gateway_method" "auth_signup_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signup_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.auth_signup.id
  http_method = aws_api_gateway_method.auth_signup_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.signup.invoke_arn
}

# Auth signin POST method
resource "aws_api_gateway_method" "auth_signin_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_signin.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signin_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.auth_signin.id
  http_method = aws_api_gateway_method.auth_signin_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.signin.invoke_arn
}

# Auth confirm POST method
resource "aws_api_gateway_method" "auth_confirm_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_confirm.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_confirm_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.auth_confirm.id
  http_method = aws_api_gateway_method.auth_confirm_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.confirm_signup.invoke_arn
}

# Auth profile GET method
resource "aws_api_gateway_method" "auth_profile_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_profile.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "auth_profile_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_profile.invoke_arn
}

# Users POST method
resource "aws_api_gateway_method" "users_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "users_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = aws_api_gateway_method.users_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.create_user.invoke_arn
}

# Users/{id} GET method
resource "aws_api_gateway_method" "users_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "users_id_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.users_id.id
  http_method = aws_api_gateway_method.users_id_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_user.invoke_arn
}

# Users/{id} PUT method
resource "aws_api_gateway_method" "users_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users_id.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "users_id_put_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.users_id.id
  http_method = aws_api_gateway_method.users_id_put.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.update_user.invoke_arn
}

# Users/{id} DELETE method
resource "aws_api_gateway_method" "users_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users_id.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "users_id_delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.users_id.id
  http_method = aws_api_gateway_method.users_id_delete.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.delete_user.invoke_arn
}

# Products GET method
resource "aws_api_gateway_method" "products_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_products.invoke_arn
}

# Products POST method
resource "aws_api_gateway_method" "products_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "products_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.create_product.invoke_arn
}

# Products/{id} GET method
resource "aws_api_gateway_method" "products_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_id_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products_id.id
  http_method = aws_api_gateway_method.products_id_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_product.invoke_arn
}

# Products/{id} PUT method
resource "aws_api_gateway_method" "products_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products_id.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "products_id_put_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products_id.id
  http_method = aws_api_gateway_method.products_id_put.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.update_product.invoke_arn
}

# Products/{id} DELETE method
resource "aws_api_gateway_method" "products_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products_id.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "products_id_delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products_id.id
  http_method = aws_api_gateway_method.products_id_delete.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.delete_product.invoke_arn
}

# Orders GET method
resource "aws_api_gateway_method" "orders_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "orders_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_orders.invoke_arn
}

# Orders POST method
resource "aws_api_gateway_method" "orders_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "orders_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.create_order.invoke_arn
}

# Files GET method (list files)
resource "aws_api_gateway_method" "files_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "files_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.files_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.list_files.invoke_arn
}

# Files/upload POST method
resource "aws_api_gateway_method" "files_upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.files_upload.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "files_upload_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.files_upload.id
  http_method = aws_api_gateway_method.files_upload_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.upload_file.invoke_arn
}

# Files/upload-url POST method
resource "aws_api_gateway_method" "files_upload_url_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.files_upload_url.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "files_upload_url_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.files_upload_url.id
  http_method = aws_api_gateway_method.files_upload_url_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.generate_upload_url.invoke_arn
}

# Files/{filename} GET method
resource "aws_api_gateway_method" "files_filename_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.files_filename.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "files_filename_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.files_filename.id
  http_method = aws_api_gateway_method.files_filename_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.get_file.invoke_arn
}

# Files/{filename} DELETE method
resource "aws_api_gateway_method" "files_filename_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.files_filename.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "files_filename_delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.files_filename.id
  http_method = aws_api_gateway_method.files_filename_delete.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.delete_file.invoke_arn
}

# =========================================================
# Lambda Permissions for API Gateway
# =========================================================

# Auth function permissions
resource "aws_lambda_permission" "allow_api_gateway_signup" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_signin" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signin.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_confirm_signup" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.confirm_signup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_profile" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_profile.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# User function permissions
resource "aws_lambda_permission" "allow_api_gateway_create_user" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_user" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_update_user" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_delete_user" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Product function permissions
resource "aws_lambda_permission" "allow_api_gateway_create_product" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_products" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_products.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_product" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_update_product" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_delete_product" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Order function permissions
resource "aws_lambda_permission" "allow_api_gateway_create_order" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_orders" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_orders.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# File function permissions
resource "aws_lambda_permission" "allow_api_gateway_upload_file" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_file.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_get_file" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_file.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_list_files" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_files.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_delete_file" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_file.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_generate_upload_url" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_upload_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# =========================================================
# API Gateway Deployment
# =========================================================

resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.auth_signup_integration,
    aws_api_gateway_integration.auth_signin_integration,
    aws_api_gateway_integration.auth_confirm_integration,
    aws_api_gateway_integration.auth_profile_integration,
    aws_api_gateway_integration.users_post_integration,
    aws_api_gateway_integration.users_id_get_integration,
    aws_api_gateway_integration.users_id_put_integration,
    aws_api_gateway_integration.users_id_delete_integration,
    aws_api_gateway_integration.products_get_integration,
    aws_api_gateway_integration.products_post_integration,
    aws_api_gateway_integration.products_id_get_integration,
    aws_api_gateway_integration.products_id_put_integration,
    aws_api_gateway_integration.products_id_delete_integration,
    aws_api_gateway_integration.orders_get_integration,
    aws_api_gateway_integration.orders_post_integration,
    aws_api_gateway_integration.files_get_integration,
    aws_api_gateway_integration.files_upload_integration,
    aws_api_gateway_integration.files_upload_url_integration,
    aws_api_gateway_integration.files_filename_get_integration,
    aws_api_gateway_integration.files_filename_delete_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.auth.id,
      aws_api_gateway_resource.users.id,
      aws_api_gateway_resource.products.id,
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_resource.files.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller                 = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-api-stage-${var.environment}"
    Type = "API Gateway Stage"
  })
}

# Method settings for throttling
resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch metrics and logs
    metrics_enabled = true
    logging_level   = var.api_gateway_log_level

    # Throttling settings
    throttling_rate_limit  = var.api_gateway_throttling_rate_limit
    throttling_burst_limit = var.api_gateway_throttling_burst_limit
  }
}

# =========================================================
# CloudWatch Alarms (Optional)
# =========================================================

# SNS topic for alarm notifications
resource "aws_sns_topic" "alarms" {
  count = var.enable_cloudwatch_alarms && var.alarm_notification_email != "" ? 1 : 0
  name  = "${local.service_name}-alarms-${var.environment}"

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-alarms-${var.environment}"
    Type = "SNS"
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.enable_cloudwatch_alarms && var.alarm_notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

# Lambda error rate alarm
resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  count = var.enable_cloudwatch_alarms && var.enable_error_rate_alarm ? 1 : 0

  alarm_name          = "${local.service_name}-lambda-error-rate-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "120"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors lambda error rate"

  dimensions = {
    FunctionName = aws_lambda_function.signup.function_name
  }

  alarm_actions = var.alarm_notification_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-lambda-error-alarm-${var.environment}"
    Type = "CloudWatch Alarm"
  })
}

# API Gateway latency alarm
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count = var.enable_cloudwatch_alarms && var.enable_latency_alarm ? 1 : 0

  alarm_name          = "${local.service_name}-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "120"
  statistic           = "Average"
  threshold           = var.latency_threshold_ms
  alarm_description   = "This metric monitors API Gateway latency"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  alarm_actions = var.alarm_notification_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  tags = merge(local.common_tags, {
    Name = "${local.service_name}-api-latency-alarm-${var.environment}"
    Type = "CloudWatch Alarm"
  })
}

# =========================================================
# CORS Support for API Gateway
# =========================================================

# Enable CORS for all methods
resource "aws_api_gateway_method" "cors_method" {
  for_each = toset([
    aws_api_gateway_resource.auth.id,
    aws_api_gateway_resource.auth_signup.id,
    aws_api_gateway_resource.auth_signin.id,
    aws_api_gateway_resource.auth_confirm.id,
    aws_api_gateway_resource.auth_profile.id,
    aws_api_gateway_resource.users.id,
    aws_api_gateway_resource.users_id.id,
    aws_api_gateway_resource.products.id,
    aws_api_gateway_resource.products_id.id,
    aws_api_gateway_resource.orders.id,
    aws_api_gateway_resource.files.id,
    aws_api_gateway_resource.files_upload.id,
    aws_api_gateway_resource.files_upload_url.id,
    aws_api_gateway_resource.files_filename.id,
  ])

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  for_each = aws_api_gateway_method.cors_method

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "cors_method_response" {
  for_each = aws_api_gateway_method.cors_method

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  for_each = aws_api_gateway_integration.cors_integration

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = aws_api_gateway_method_response.cors_method_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,HEAD,OPTIONS,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_method.cors_method]
}

# =========================================================
# Gateway Responses for CORS
# =========================================================

resource "aws_api_gateway_gateway_response" "cors_gateway_response" {
  for_each = toset([
    "DEFAULT_4XX",
    "DEFAULT_5XX",
    "UNAUTHORIZED",
    "ACCESS_DENIED"
  ])

  rest_api_id   = aws_api_gateway_rest_api.main.id
  response_type = each.value

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,HEAD,OPTIONS,POST,PUT,DELETE'"
  }
}