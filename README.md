# AWS CRUD Microservices

This project demonstrates a serverless CRUD microservices architecture using AWS Lambda, API Gateway, DynamoDB, SNS, and SQS. It includes local development support with in-memory mocking for quick testing.

## Features
- User, Product, Order, and Notification microservices
- **AWS S3 File Storage** - Upload, download, list, and delete files with LocalStack support
- **JWT Authentication & Authorization** - Secure API access with user-scoped permissions
- Input validation with Joi
- Messaging with SNS and SQS (mocked for local development)
- Local development with in-memory database mocking
- **LocalStack Integration** - Full local AWS service emulation
- **In-Memory Fallback** - Mock storage when LocalStack unavailable
- Unit tests with Jest

## Project Structure
```
handlers/         # Lambda function handlers for each microservice
  users.js        # User CRUD operations
  products.js     # Product CRUD operations  
  orders.js       # Order CRUD operations
  notifications.js# Event processing
  auth.js         # Authentication (signup, signin, profile)
  files.js        # File storage operations (S3 integration)
utils/            # Shared utility modules
  dynamodb.js     # Database operations (with local mocking)
  messaging.js    # SNS/SQS operations (with local mocking)
  mockdb.js       # In-memory database for local development
  mockAuth.js     # In-memory authentication for local development
  validation.js   # Joi validation schemas
  response.js     # HTTP response utilities
  extractUser.js  # User extraction utilities
  auth.js         # JWT token handling
  s3.js           # S3 operations with LocalStack support
tests/            # Jest test files
serverless.yml    # Serverless Framework configuration
package.json      # Project dependencies and scripts
docker-compose.yml# Local AWS service emulation (optional)
S3_INTEGRATION.md # Detailed S3 integration documentation
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

### Authentication (New!)
- **Sign Up:** `POST http://localhost:3000/dev/auth/signup`
  ```bash
  curl -X POST http://localhost:3000/dev/auth/signup \
    -H "Content-Type: application/json" \
    -d '{"email":"user@example.com","password":"TestPass123","name":"John Doe"}'
  ```

- **Sign In:** `POST http://localhost:3000/dev/auth/signin`
  ```bash
  curl -X POST http://localhost:3000/dev/auth/signin \
    -H "Content-Type: application/json" \
    -d '{"email":"user@example.com","password":"TestPass123"}'
  ```

- **Get Profile:** `GET http://localhost:3000/dev/auth/profile` (Requires JWT token)
  ```bash
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:3000/dev/auth/profile
  ```

### Users (Requires Authentication*)
- **Create User:** `POST http://localhost:3000/dev/users`
  ```bash
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    -X POST http://localhost:3000/dev/users \
    -H "Content-Type: application/json" \
    -d '{"name":"John Doe","email":"john@example.com","age":30,"phone":"+1234567890"}'
  ```

- **Get User:** `GET http://localhost:3000/dev/users/{id}` (Requires Authentication*)
- **Update User:** `PUT http://localhost:3000/dev/users/{id}` (Requires Authentication*)
- **Delete User:** `DELETE http://localhost:3000/dev/users/{id}` (Requires Authentication*)

### Products
- **Create Product:** `POST http://localhost:3000/dev/products` (Requires Authentication*)
  ```bash
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    -X POST http://localhost:3000/dev/products \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Product","description":"A test product","price":29.99,"category":"Electronics"}'
  ```

- **Get All Products:** `GET http://localhost:3000/dev/products` (Public)
- **Get Product:** `GET http://localhost:3000/dev/products/{id}` (Public)
- **Update Product:** `PUT http://localhost:3000/dev/products/{id}` (Requires Authentication*)
- **Delete Product:** `DELETE http://localhost:3000/dev/products/{id}` (Requires Authentication*)

### Orders (Requires Authentication*)
- **Create Order:** `POST http://localhost:3000/dev/orders`
- **Get All Orders:** `GET http://localhost:3000/dev/orders`

### Files & S3 Storage (Requires Authentication*)
- **Upload File:** `POST http://localhost:3000/dev/files/upload`
  ```bash
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    -X POST http://localhost:3000/dev/files/upload \
    -H "Content-Type: application/json" \
    -d '{"fileName":"document.txt","fileContent":"SGVsbG8gV29ybGQ=","contentType":"text/plain"}'
  ```

- **List Files:** `GET http://localhost:3000/dev/files?userOnly=true`
  ```bash
  curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    "http://localhost:3000/dev/files?userOnly=true"
  ```

- **Download File:** `GET http://localhost:3000/dev/files/{key}`
- **Delete File:** `DELETE http://localhost:3000/dev/files/{key}`
- **Generate Upload URL:** `POST http://localhost:3000/dev/files/upload-url`

_See detailed S3 integration guide in `S3_INTEGRATION.md`_

*_Note: Authentication is enforced in production but bypassed in local development for easier testing._

## Local Development Features

### AWS Cognito Authentication
- **Local Development:** Uses JWT tokens with HMAC-SHA256 signing
- **Production:** Uses AWS Cognito User Pools with RS256 signing
- **Mock Authentication:** In-memory user storage for local testing
- **Seamless Switching:** Automatically detects environment and switches auth methods

### In-Memory Database
- Uses `utils/mockdb.js` for local development
- Data persists during the serverless offline session
- Automatically switches between mock (local) and real AWS (production)

### Mock Services
- **DynamoDB:** In-memory JavaScript Map storage
- **SNS/SQS:** Console logging instead of actual messaging
- **Cognito:** JWT token generation and validation for local development

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
## Troubleshooting

### Common Issues

1. **"Missing credentials in config" Error**
   ```bash
   # Set dummy AWS credentials before starting serverless offline
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export IS_OFFLINE=true
   ```

2. **Port Already in Use**
   ```bash
   # Kill existing Node.js processes
   taskkill //F //IM node.exe  # Windows
   # Or use a different port
   serverless offline --httpPort 3001
   ```

3. **Java Not Found (DynamoDB Local)**
   - This project uses in-memory mocking instead of DynamoDB Local
   - No Java installation required for local development

4. **Empty Results from GET Endpoints**
   - Data is stored in-memory during the serverless offline session
   - Create some data first using POST endpoints
   - Data is lost when serverless offline is restarted

### Node.js Version Management (Windows)

If you need to switch Node.js versions:

1. **Install nvm-windows:**
   - Download from: https://github.com/coreybutler/nvm-windows/releases
   - Install the `.exe` file

2. **Use Node.js 20.x:**
   ```bash
   nvm install 20.19.3
   nvm use 20.19.3
   ```

3. **Verify installation:**
   ```bash
   node --version  # Should show v20.x.x
   npm --version
   ```

## Testing the API

### Complete Step-by-Step Examples

#### 1. Start the Development Server
```bash
# Navigate to project directory
cd aws-tutorial-1

# Set environment variables (choose your platform)
# For Git Bash/WSL:
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export IS_OFFLINE=true

# For Windows Command Prompt:
set AWS_ACCESS_KEY_ID=test
set AWS_SECRET_ACCESS_KEY=test
set IS_OFFLINE=true

# For PowerShell:
$env:AWS_ACCESS_KEY_ID="test"
$env:AWS_SECRET_ACCESS_KEY="test"
$env:IS_OFFLINE="true"

# Start the serverless offline server
serverless offline
```

Wait for the server to start. You should see output like:
```
Server ready: http://localhost:3003 🚀
```

#### 2. Authentication Flow

**Step 2.1: Sign Up a New User**
```bash
curl -X POST http://localhost:3003/dev/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "TempPass123!",
    "name": "Test User"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "message": "User created successfully",
    "user": {
      "id": "49b38958-0c49-4bb3-919b-6d40b4c66177",
      "email": "testuser@example.com",
      "name": "Test User"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "needsConfirmation": false
  }
}
```

**Step 2.2: Save the JWT Token**
Copy the token from the response above and save it as an environment variable:
```bash
# Save the token for future requests
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Step 2.3: Test Authentication with Profile**
```bash
curl -X GET http://localhost:3003/dev/auth/profile \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "userId": "49b38958-0c49-4bb3-919b-6d40b4c66177",
      "email": "testuser@example.com",
      "name": "Test User"
    }
  }
}
```

#### 3. User Management Examples

**Step 3.1: Create a User Profile**
```bash
curl -X POST http://localhost:3003/dev/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30,
    "phone": "+1234567890"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-123-456",
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30,
    "phone": "+1234567890",
    "createdAt": "2025-01-05T20:30:00.000Z",
    "updatedAt": "2025-01-05T20:30:00.000Z"
  }
}
```

**Step 3.2: Get User Profile (save the user ID from step 3.1)**
```bash
# Replace USER_ID with the actual ID from the create response
export USER_ID="user-123-456"

curl -X GET http://localhost:3003/dev/users/$USER_ID \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Step 3.3: Update User Profile**
```bash
curl -X PUT http://localhost:3003/dev/users/$USER_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "name": "John Smith",
    "email": "johnsmith@example.com",
    "age": 31,
    "phone": "+1234567891"
  }'
```

#### 4. Product Management Examples

**Step 4.1: Create Products**
```bash
# Create first product
curl -X POST http://localhost:3003/dev/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "name": "Laptop",
    "description": "High-performance laptop for developers",
    "price": 1299.99,
    "category": "Electronics"
  }'

# Create second product
curl -X POST http://localhost:3003/dev/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "name": "Wireless Mouse",
    "description": "Ergonomic wireless mouse",
    "price": 29.99,
    "category": "Electronics"
  }'
```

**Step 4.2: List All Products (Public - No Authentication Required)**
```bash
curl -X GET http://localhost:3003/dev/products
```

**Step 4.3: Get Specific Product (save product ID from step 4.1)**
```bash
export PRODUCT_ID="product-123-456"

curl -X GET http://localhost:3003/dev/products/$PRODUCT_ID
```

**Step 4.4: Update Product**
```bash
curl -X PUT http://localhost:3003/dev/products/$PRODUCT_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "name": "Gaming Laptop",
    "description": "High-performance gaming laptop",
    "price": 1499.99,
    "category": "Gaming"
  }'
```

#### 5. Order Management Examples

**Step 5.1: Create Orders**
```bash
# Create first order
curl -X POST http://localhost:3003/dev/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "productId": "'$PRODUCT_ID'",
    "quantity": 1,
    "totalAmount": 1499.99
  }'

# Create second order
curl -X POST http://localhost:3003/dev/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "productId": "another-product-id",
    "quantity": 2,
    "totalAmount": 59.98
  }'
```

**Step 5.2: List All Orders**
```bash
curl -X GET http://localhost:3003/dev/orders \
  -H "Authorization: Bearer $JWT_TOKEN"
```

#### 6. File Storage Examples (S3 Integration)

**Step 6.1: Upload a File**
```bash
# Create base64 encoded content
echo "Hello from S3 test file!" | base64 > /tmp/content.txt
CONTENT=$(cat /tmp/content.txt)

# Upload the file
curl -X POST http://localhost:3003/dev/files/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "fileName": "test-document.txt",
    "fileContent": "'$CONTENT'",
    "contentType": "text/plain",
    "metadata": {
      "description": "Test file upload",
      "category": "documents"
    }
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "message": "File uploaded successfully",
    "file": {
      "key": "uploads/49b38958-0c49-4bb3-919b-6d40b4c66177/1751732678214-test-document.txt",
      "originalName": "test-document.txt",
      "location": "http://localhost:3000/mock-s3/uploads/...",
      "contentType": "text/plain",
      "uploadedBy": "49b38958-0c49-4bb3-919b-6d40b4c66177",
      "uploadedAt": "2025-01-05T20:30:00.000Z"
    }
  }
}
```

**Step 6.2: List User's Files**
```bash
curl -X GET "http://localhost:3003/dev/files?userOnly=true&maxKeys=10" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Step 6.3: Download a File (save the file key from step 6.1)**
```bash
export FILE_KEY="uploads/49b38958-0c49-4bb3-919b-6d40b4c66177/1751732678214-test-document.txt"

curl -X GET "http://localhost:3003/dev/files/$FILE_KEY" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**Step 6.4: Generate Presigned Upload URL**
```bash
curl -X POST http://localhost:3003/dev/files/upload-url \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "fileName": "large-document.pdf",
    "contentType": "application/pdf",
    "expiresIn": 3600
  }'
```

**Step 6.5: Delete a File**
```bash
curl -X DELETE "http://localhost:3003/dev/files/$FILE_KEY" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

#### 7. Complete Test Script

Create a file called `test-api.sh` with all the commands:

```bash
#!/bin/bash

# Set base URL
BASE_URL="http://localhost:3003/dev"

echo "🚀 Starting API Test Suite..."

# 1. Sign up
echo "📝 1. Creating user account..."
SIGNUP_RESPONSE=$(curl -s -X POST $BASE_URL/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@example.com","password":"DemoPass123!","name":"Demo User"}')

echo "✅ Signup Response: $SIGNUP_RESPONSE"

# Extract token
JWT_TOKEN=$(echo $SIGNUP_RESPONSE | jq -r '.data.token')
echo "🔑 JWT Token extracted: ${JWT_TOKEN:0:50}..."

# 2. Create user profile
echo "👤 2. Creating user profile..."
USER_RESPONSE=$(curl -s -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name":"Demo User","email":"demo@example.com","age":25,"phone":"+1234567890"}')

echo "✅ User Created: $USER_RESPONSE"

# Extract user ID
USER_ID=$(echo $USER_RESPONSE | jq -r '.data.id')

# 3. Create product
echo "📦 3. Creating product..."
PRODUCT_RESPONSE=$(curl -s -X POST $BASE_URL/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name":"Demo Product","description":"A demo product","price":99.99,"category":"Demo"}')

echo "✅ Product Created: $PRODUCT_RESPONSE"

# Extract product ID
PRODUCT_ID=$(echo $PRODUCT_RESPONSE | jq -r '.data.id')

# 4. List products
echo "📋 4. Listing all products..."
curl -s -X GET $BASE_URL/products | jq .

# 5. Create order
echo "🛒 5. Creating order..."
ORDER_RESPONSE=$(curl -s -X POST $BASE_URL/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"userId\":\"$USER_ID\",\"productId\":\"$PRODUCT_ID\",\"quantity\":1,\"totalAmount\":99.99}")

echo "✅ Order Created: $ORDER_RESPONSE"

# 6. Upload file
echo "📁 6. Uploading file..."
CONTENT=$(echo "Hello from API test!" | base64)
FILE_RESPONSE=$(curl -s -X POST $BASE_URL/files/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"fileName\":\"test.txt\",\"fileContent\":\"$CONTENT\",\"contentType\":\"text/plain\"}")

echo "✅ File Uploaded: $FILE_RESPONSE"

# 7. List files
echo "📂 7. Listing user files..."
curl -s -X GET "$BASE_URL/files?userOnly=true" \
  -H "Authorization: Bearer $JWT_TOKEN" | jq .

echo "🎉 API Test Suite Completed!"
```

Make it executable and run:
```bash
chmod +x test-api.sh
./test-api.sh
```

#### 8. Browser Testing

You can also test GET endpoints directly in your browser:

1. **View all products:** http://localhost:3003/dev/products
2. **Health check:** http://localhost:3003/dev/health (if implemented)

#### 9. Troubleshooting Test Issues

**Problem: "Unauthorized" errors**
- Make sure you're using the correct JWT token
- Check that the token hasn't expired
- Verify the Authorization header format: `Bearer <token>`

**Problem: "User not found" errors**
- Make sure you're using the correct user ID from the creation response
- Check that the user was created successfully

**Problem: Connection refused**
- Verify serverless offline is running on the correct port
- Check for port conflicts (try port 3003 if 3000 is busy)

**Problem: Base64 encoding issues**
- For Windows: `powershell -command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('Hello World'))"`
- For Linux/Mac: `echo "Hello World" | base64`

This completes the comprehensive step-by-step testing guide for your AWS CRUD microservices with S3 integration! 🎯

### Using in Browser

Open your browser and visit:
- `http://localhost:3000/dev/products` - Get all products
- `http://localhost:3000/dev/orders` - Get all orders

## Production Deployment

For production deployment to AWS:

1. **Remove local development flags:**
   - Remove `IS_OFFLINE` and `NODE_ENV` environment variables
   - Ensure real AWS credentials are configured

2. **Deploy to AWS:**
   ```bash
   serverless deploy --stage production
   ```

3. **The application will automatically use:**
   - Real AWS DynamoDB tables
   - Real SNS/SQS services
   - Proper authentication/authorization

## Architecture

### Complete System Architecture
![Alt text](media/diagram-1.png)

### Microservices Breakdown
![Alt text](media/diagram-2.png)

### Local Development Architecture
![Alt text](media/diagram-3.png)

### Production AWS Architecture
![Alt text](media/diagram-4.png)

### Security & Data Flow
![Alt text](media/diagram-5.png)
## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `serverless offline`
5. Submit a pull request

## License

MIT License
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
