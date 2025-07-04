# AWS CRUD Microservices

This project demonstrates a serverless CRUD microservices architecture using AWS Lambda, API Gateway, DynamoDB, SNS, and SQS. It includes local development support with Docker Compose for DynamoDB Local and LocalStack.

## Features
- User, Product, Order, and Notification microservices
- Input validation with Joi
- Authentication and authorization utilities
- Messaging with SNS and SQS
- Local development with Docker Compose
- Unit tests with Jest

## Project Structure
```
handlers/         # Lambda function handlers for each microservice
  users.js
  products.js
  orders.js
  notifications.js
utils/            # Shared utility modules (auth, validation, db, messaging, etc.)
tests/            # Jest test files
serverless.yml    # Serverless Framework configuration
package.json      # Project dependencies and scripts
docker-compose.yml# Local AWS service emulation
```

## Local Development

### Prerequisites
- Node.js (v16+ recommended)
- Docker & Docker Compose
- Serverless Framework (`npm install -g serverless`)

### Setup
1. Install dependencies:
   ```bash
   npm install
   ```
2. Start local AWS services:
   ```bash
   docker-compose up -d
   ```
3. Deploy locally (with serverless-offline):
   ```bash
   serverless offline
   ```

## Running Tests
```bash
npm test
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
