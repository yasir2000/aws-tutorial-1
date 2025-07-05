# AWS CRUD Microservices

This project demonstrates a serverless CRUD microservices architecture using AWS Lambda, API Gateway, DynamoDB, SNS, and SQS. It includes local development support with in-memory mocking for quick testing.

## Features
- User, Product, Order, and Notification microservices
- Input validation with Joi
- Authentication and authorization utilities (bypassed for local development)
- Messaging with SNS and SQS (mocked for local development)
- Local development with in-memory database mocking
- Unit tests with Jest

## Project Structure
```
handlers/         # Lambda function handlers for each microservice
  users.js        # User CRUD operations
  products.js     # Product CRUD operations  
  orders.js       # Order CRUD operations
  notifications.js# Event processing
utils/            # Shared utility modules
  dynamodb.js     # Database operations (with local mocking)
  messaging.js    # SNS/SQS operations (with local mocking)
  mockdb.js       # In-memory database for local development
  validation.js   # Joi validation schemas
  response.js     # HTTP response utilities
  extractUser.js  # User extraction utilities
tests/            # Jest test files
serverless.yml    # Serverless Framework configuration
package.json      # Project dependencies and scripts
docker-compose.yml# Local AWS service emulation (optional)
```

## Quick Start

### Prerequisites
- Node.js 20.x (use nvm-windows to manage versions)
- Serverless Framework (`npm install -g serverless`)

### Setup
1. **Clone and install dependencies:**
   ```bash
   git clone <your-repo>
   cd aws-tutorial-1
   npm install
   ```

2. **Set environment variables for local development:**
   ```bash
   # For Git Bash/WSL
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export IS_OFFLINE=true

   # For Windows Command Prompt
   set AWS_ACCESS_KEY_ID=test
   set AWS_SECRET_ACCESS_KEY=test
   set IS_OFFLINE=true

   # For PowerShell
   $env:AWS_ACCESS_KEY_ID="test"
   $env:AWS_SECRET_ACCESS_KEY="test"
   $env:IS_OFFLINE="true"
   ```

3. **Start the local server:**
   ```bash
   serverless offline
   ```

4. **API will be available at:** `http://localhost:3000`

## API Endpoints

### Users
- **Create User:** `POST http://localhost:3000/dev/users`
  ```bash
  curl -X POST http://localhost:3000/dev/users \
    -H "Content-Type: application/json" \
    -d '{"name":"John Doe","email":"john@example.com","age":30,"phone":"+1234567890"}'
  ```

- **Get User:** `GET http://localhost:3000/dev/users/{id}`
- **Update User:** `PUT http://localhost:3000/dev/users/{id}`
- **Delete User:** `DELETE http://localhost:3000/dev/users/{id}`

### Products
- **Create Product:** `POST http://localhost:3000/dev/products`
  ```bash
  curl -X POST http://localhost:3000/dev/products \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Product","description":"A test product","price":29.99,"category":"Electronics"}'
  ```

- **Get All Products:** `GET http://localhost:3000/dev/products`
- **Get Product:** `GET http://localhost:3000/dev/products/{id}`
- **Update Product:** `PUT http://localhost:3000/dev/products/{id}`
- **Delete Product:** `DELETE http://localhost:3000/dev/products/{id}`

### Orders
- **Create Order:** `POST http://localhost:3000/dev/orders`
- **Get All Orders:** `GET http://localhost:3000/dev/orders`

## Local Development Features

### In-Memory Database
- Uses `utils/mockdb.js` for local development
- Data persists during the serverless offline session
- Automatically switches between mock (local) and real AWS (production)

### Mock Services
- **DynamoDB:** In-memory JavaScript Map storage
- **SNS/SQS:** Console logging instead of actual messaging
- **Authentication:** Bypassed for local development

### Environment Detection
The application automatically detects local development through:
- `IS_OFFLINE=true` environment variable
- `NODE_ENV=development` environment variable

## Running Tests
```bash
npm test
```
```

## Environment Variables
Set these in your environment or a `.env` file:
- `USERS_TABLE` - DynamoDB table name for users
- `PRODUCTS_TABLE` - DynamoDB table name for products
- `ORDERS_TABLE` - DynamoDB table name for orders
- `AWS_REGION` - AWS region (e.g., us-east-1)
- `AWS_ACCOUNT_ID` - Your AWS account ID (for LocalStack)
- `SNS_TOPIC` - SNS topic name
- `SQS_QUEUE` - SQS queue name

## Use AWS CLI to create the neccessary resources on LocalStack
```bash
aws dynamodb create-table --table-name $USERS_TABLE \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --endpoint-url=http://localhost:4566 --region $AWS_REGION

aws dynamodb create-table --table-name $PRODUCTS_TABLE \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --endpoint-url=http://localhost:4566 --region $AWS_REGION

aws dynamodb create-table --table-name $ORDERS_TABLE \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --endpoint-url=http://localhost:4566 --region $AWS_REGION
```

Create SNS Topic

```bash
aws sns create-topic --name $SNS_TOPIC \
  --endpoint-url=http://localhost:4566 --region $AWS_REGION
```

Create SQS Topic
```bash
aws sqs create-queue --queue-name $SQS_QUEUE \
  --endpoint-url=http://localhost:4566 --region $AWS_REGION
```

## Using AWS CLI with LocalStack

To use AWS CLI commands with LocalStack, follow these steps:

1. **Start LocalStack**
   ```bash
   docker-compose up -d
   ```

2. **Set Dummy AWS Credentials**
   LocalStack does not require real AWS credentials, but the AWS CLI expects them to be set:
   ```bash
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   ```
   Or add them to your `.env` file.

3. **Always Use the LocalStack Endpoint**
   Add `--endpoint-url=http://localhost:4566` to all AWS CLI commands. Example:
   ```bash
   aws dynamodb list-tables --endpoint-url=http://localhost:4566 --region us-east-1
   ```

4. **Create Resources Example**
   ```bash
   aws dynamodb create-table --table-name users \
     --attribute-definitions AttributeName=id,AttributeType=S \
     --key-schema AttributeName=id,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
     --endpoint-url=http://localhost:4566 --region us-east-1

   aws sns create-topic --name my-sns-topic --endpoint-url=http://localhost:4566 --region us-east-1
   aws sqs create-queue --queue-name my-sqs-queue --endpoint-url=http://localhost:4566 --region us-east-1
   ```

5. **Troubleshooting**
   - Check LocalStack logs: `docker logs localstack`
   - Make sure port 4566 is open and not blocked.
   - If using Git Bash, ensure AWS CLI is in your PATH.

**Tip:** You can script these commands in a file (e.g., `init-localstack.sh`) for convenience.

## Deploying and Testing the API Locally

After creating the resources on LocalStack, follow these steps to deploy and test your API:

### 1. Deploy Locally with Serverless Offline

Make sure you have the Serverless Framework and serverless-offline plugin installed:
```bash
npm install -g serverless
npm install --save-dev serverless-offline
```

Start the local API Gateway and Lambda emulation:
```bash
serverless offline
```
This will start your API on a local port (usually http://localhost:3000).

### 2. Test the API Endpoints

You can use `curl`, Postman, or any HTTP client to test your endpoints. Example using `curl`:

**Create a user:**
```bash
curl -X POST http://localhost:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"John Doe","email":"john@example.com","age":30,"phone":"+1234567890"}'
```

**Get a user:**
```bash
curl http://localhost:3000/users/{userId}
```

**Update a user:**
```bash
curl -X PUT http://localhost:3000/users/{userId} \
  -H 'Content-Type: application/json' \
  -d '{"name":"Jane Doe","email":"jane@example.com","age":28,"phone":"+1234567890"}'
```

**Delete a user:**
```bash
curl -X DELETE http://localhost:3000/users/{userId}
```

### 3. Run Automated Tests

You can also run the included Jest tests:
```bash
npm test
```

---

**Tip:**
- Check the Serverless Offline output for the exact URLs and ports.
- Make sure your environment variables are set or your `.env` file is loaded.
- You can use Postman for more advanced API testing.

## Useful Commands
- Deploy to AWS:
  ```bash
  npm run deploy
  ```
- Run tests:
  ```bash
  npm test
  ```
- Start local AWS emulation:
  ```bash
  docker-compose up -d
  ```

## Notes
- DynamoDB Local and LocalStack are used for local development and testing. No real AWS resources are required.
- See `serverless.yml` for function and resource definitions.
- See `docker-compose.yml` for local service configuration.

## License
MIT
