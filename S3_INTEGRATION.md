# AWS S3 File Storage Integration

## Overview

This microservice now includes complete AWS S3 bucket object storage functionality with LocalStack support for local development. The implementation provides secure file upload, download, listing, and deletion capabilities with JWT-based authentication.

## Features

### ✅ Implemented Features

1. **File Upload** - Upload files with base64 content or via presigned URLs
2. **File Download** - Download files by key with authentication
3. **File Listing** - List files with optional user-specific filtering
4. **File Deletion** - Delete files with ownership validation
5. **Presigned URL Generation** - Generate secure upload URLs for direct S3 uploads
6. **LocalStack Support** - Local development with LocalStack S3 emulation
7. **In-Memory Fallback** - Mock storage when LocalStack is not available
8. **JWT Authentication** - All file operations require valid JWT tokens
9. **User-scoped Files** - Files are organized by user ID for security

## S3 Storage Configuration

### Environment Variables
```
S3_BUCKET=crud-microservices-files-dev
S3_ENDPOINT=http://localhost:4566  # LocalStack endpoint (optional)
IS_OFFLINE=true  # Enables local development mode
```

### LocalStack Setup
For local development with S3 emulation:
```bash
# Start LocalStack (if using Docker Compose)
docker-compose up localstack

# Or install LocalStack directly
pip install localstack
localstack start
```

## API Endpoints

### 1. File Upload
**POST** `/dev/files/upload`
```bash
curl -X POST http://localhost:3003/dev/files/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{
    "fileName": "document.txt",
    "fileContent": "SGVsbG8gV29ybGQ=",  # Base64 encoded content
    "contentType": "text/plain",
    "metadata": {
      "description": "Sample document"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "File uploaded successfully",
    "file": {
      "key": "uploads/user-id/timestamp-document.txt",
      "originalName": "document.txt",
      "location": "http://localhost:3000/mock-s3/uploads/user-id/timestamp-document.txt",
      "bucket": "crud-microservices-files-dev",
      "contentType": "text/plain",
      "uploadedBy": "user-id",
      "uploadedAt": "2025-01-05T20:30:00.000Z"
    }
  }
}
```

### 2. List Files
**GET** `/dev/files`
```bash
curl -X GET "http://localhost:3003/dev/files?userOnly=true&maxKeys=10" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "files": [
      {
        "key": "uploads/user-id/timestamp-document.txt",
        "lastModified": "2025-01-05T20:30:00.000Z",
        "size": 1024,
        "etag": "\"abc123\"",
        "storageClass": "STANDARD"
      }
    ],
    "count": 1,
    "isTruncated": false,
    "prefix": "uploads/user-id/"
  }
}
```

### 3. Get File
**GET** `/dev/files/{key}`
```bash
curl -X GET "http://localhost:3003/dev/files/uploads/user-id/timestamp-document.txt" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "key": "uploads/user-id/timestamp-document.txt",
    "content": "SGVsbG8gV29ybGQ=",  # Base64 encoded content
    "contentType": "text/plain",
    "metadata": {
      "uploadedBy": "user-id",
      "uploadedAt": "2025-01-05T20:30:00.000Z"
    },
    "lastModified": "2025-01-05T20:30:00.000Z"
  }
}
```

### 4. Delete File
**DELETE** `/dev/files/{key}`
```bash
curl -X DELETE "http://localhost:3003/dev/files/uploads/user-id/timestamp-document.txt" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "File deleted successfully",
    "key": "uploads/user-id/timestamp-document.txt"
  }
}
```

### 5. Generate Presigned Upload URL
**POST** `/dev/files/upload-url`
```bash
curl -X POST http://localhost:3003/dev/files/upload-url \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{
    "fileName": "large-file.pdf",
    "contentType": "application/pdf",
    "expiresIn": 3600
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "uploadUrl": "http://localhost:3000/mock-s3/upload/uploads/user-id/timestamp-large-file.pdf",
    "key": "uploads/user-id/timestamp-large-file.pdf",
    "bucket": "crud-microservices-files-dev",
    "expiresIn": 3600,
    "fileName": "large-file.pdf",
    "contentType": "application/pdf"
  }
}
```

## File Organization

Files are automatically organized in the S3 bucket using the following structure:
```
bucket-name/
├── uploads/
│   ├── user-id-1/
│   │   ├── timestamp-file1.txt
│   │   └── timestamp-file2.pdf
│   └── user-id-2/
│       ├── timestamp-file3.jpg
│       └── timestamp-file4.doc
```

## Security Features

1. **JWT Authentication** - All endpoints require valid JWT tokens
2. **User Isolation** - Users can only access their own files
3. **File Key Validation** - Prevents unauthorized access to other users' files
4. **Content Type Validation** - Supports all MIME types with proper validation
5. **Metadata Tracking** - Tracks upload time, user, and custom metadata

## Local Development

### Using In-Memory Mock (Default)
When LocalStack is not available, the system automatically falls back to in-memory storage:
```javascript
// Automatically detected when S3_ENDPOINT is not set
console.log('MOCK S3: Uploaded file uploads/user-id/file.txt')
```

### Using LocalStack S3
Start LocalStack and set the endpoint:
```bash
# Start LocalStack
docker run -p 4566:4566 localstack/localstack

# Set environment variable
export S3_ENDPOINT=http://localhost:4566
```

## Error Handling

The API provides comprehensive error handling:

- **401 Unauthorized** - Invalid or missing JWT token
- **403 Forbidden** - Attempting to access files of other users
- **404 Not Found** - File does not exist
- **400 Bad Request** - Missing required fields
- **500 Internal Server Error** - S3 operation failures

## Testing

### Prerequisites
1. Start the serverless offline server:
```bash
npm run dev
```

2. Get a JWT token by signing up/signing in:
```bash
curl -X POST http://localhost:3003/dev/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TempPass123!","name":"Test User"}'
```

### Complete Test Flow
```bash
# 1. Sign up and get token
TOKEN=$(curl -s -X POST http://localhost:3003/dev/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TempPass123!","name":"Test User"}' | \
  jq -r '.data.token')

# 2. Upload a file
echo "Hello World!" | base64 > /tmp/content.txt
CONTENT=$(cat /tmp/content.txt)

curl -X POST http://localhost:3003/dev/files/upload \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"fileName\":\"test.txt\",\"fileContent\":\"$CONTENT\",\"contentType\":\"text/plain\"}"

# 3. List files
curl -X GET "http://localhost:3003/dev/files?userOnly=true" \
  -H "Authorization: Bearer $TOKEN"

# 4. Generate upload URL
curl -X POST http://localhost:3003/dev/files/upload-url \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"fileName":"upload.pdf","contentType":"application/pdf"}'
```

## Production Deployment

For production deployment to AWS:

1. **S3 Bucket** - Automatically created via CloudFormation in `serverless.yml`
2. **IAM Permissions** - S3 permissions already configured in the serverless role
3. **Environment Variables** - Remove `S3_ENDPOINT` for production
4. **CORS Configuration** - Configure S3 bucket CORS for web uploads

## Files Structure

- `handlers/files.js` - File operation handlers
- `utils/s3.js` - S3 utility functions with LocalStack support
- `serverless.yml` - S3 bucket and IAM configuration
- Endpoints configured with Cognito authorization

## Monitoring

The implementation includes comprehensive logging:
- File upload/download operations
- S3 operation success/failure
- User authentication events
- Error tracking with detailed messages

This completes the S3 integration for your AWS CRUD microservices architecture!
