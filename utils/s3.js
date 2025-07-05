const AWS = require('aws-sdk');
const path = require('path');

const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';

// Configure S3 for local development with LocalStack
const s3Config = {
  region: process.env.AWS_REGION || 'us-east-1',
};

if (isOffline) {
  s3Config.endpoint = process.env.S3_ENDPOINT || 'http://localhost:4566';
  s3Config.accessKeyId = 'test';
  s3Config.secretAccessKey = 'test';
  s3Config.s3ForcePathStyle = true; // Required for LocalStack
}

const s3 = new AWS.S3(s3Config);
const bucketName = process.env.S3_BUCKET;

// Mock storage for local development without LocalStack
const mockStorage = new Map();

const uploadFile = async (key, body, contentType, metadata = {}) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Use in-memory mock if LocalStack not available
    mockStorage.set(key, {
      body,
      contentType,
      metadata,
      lastModified: new Date(),
      size: Buffer.isBuffer(body) ? body.length : Buffer.byteLength(body, 'utf8')
    });
    
    console.log(`MOCK S3: Uploaded file ${key} (${contentType})`);
    return {
      Location: `http://localhost:3000/mock-s3/${key}`,
      ETag: `"${Date.now()}"`,
      Bucket: bucketName,
      Key: key
    };
  }

  const params = {
    Bucket: bucketName,
    Key: key,
    Body: body,
    ContentType: contentType,
    Metadata: metadata
  };

  try {
    const result = await s3.upload(params).promise();
    console.log(`S3: Uploaded file ${key} to ${result.Location}`);
    return result;
  } catch (error) {
    console.error('S3 upload error:', error);
    throw error;
  }
};

const getFile = async (key) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Use in-memory mock if LocalStack not available
    const file = mockStorage.get(key);
    if (!file) {
      throw new Error('File not found');
    }
    
    return {
      Body: file.body,
      ContentType: file.contentType,
      Metadata: file.metadata,
      LastModified: file.lastModified
    };
  }

  const params = {
    Bucket: bucketName,
    Key: key
  };

  try {
    const result = await s3.getObject(params).promise();
    return result;
  } catch (error) {
    console.error('S3 get error:', error);
    throw error;
  }
};

const deleteFile = async (key) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Use in-memory mock if LocalStack not available
    const existed = mockStorage.has(key);
    mockStorage.delete(key);
    console.log(`MOCK S3: Deleted file ${key}`);
    return { existed };
  }

  const params = {
    Bucket: bucketName,
    Key: key
  };

  try {
    const result = await s3.deleteObject(params).promise();
    console.log(`S3: Deleted file ${key}`);
    return result;
  } catch (error) {
    console.error('S3 delete error:', error);
    throw error;
  }
};

const listFiles = async (prefix = '', maxKeys = 1000) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Use in-memory mock if LocalStack not available
    const files = Array.from(mockStorage.entries())
      .filter(([key]) => key.startsWith(prefix))
      .slice(0, maxKeys)
      .map(([key, file]) => ({
        Key: key,
        LastModified: file.lastModified,
        Size: file.size,
        ETag: `"${Date.now()}"`,
        StorageClass: 'STANDARD'
      }));
    
    return {
      Contents: files,
      IsTruncated: false,
      KeyCount: files.length
    };
  }

  const params = {
    Bucket: bucketName,
    Prefix: prefix,
    MaxKeys: maxKeys
  };

  try {
    const result = await s3.listObjectsV2(params).promise();
    return result;
  } catch (error) {
    console.error('S3 list error:', error);
    throw error;
  }
};

const generatePresignedUrl = async (key, operation = 'getObject', expiresIn = 3600) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Return mock URL for local development
    return `http://localhost:3000/mock-s3/${key}?expires=${Date.now() + expiresIn * 1000}`;
  }

  const params = {
    Bucket: bucketName,
    Key: key,
    Expires: expiresIn
  };

  try {
    const url = await s3.getSignedUrlPromise(operation, params);
    return url;
  } catch (error) {
    console.error('S3 presigned URL error:', error);
    throw error;
  }
};

const generateUploadUrl = async (key, contentType, expiresIn = 3600) => {
  if (isOffline && !process.env.S3_ENDPOINT) {
    // Return mock upload URL for local development
    return {
      uploadUrl: `http://localhost:3000/mock-s3/upload/${key}`,
      key: key,
      bucket: bucketName
    };
  }

  const params = {
    Bucket: bucketName,
    Key: key,
    ContentType: contentType,
    Expires: expiresIn
  };

  try {
    const uploadUrl = await s3.getSignedUrlPromise('putObject', params);
    return {
      uploadUrl,
      key,
      bucket: bucketName
    };
  } catch (error) {
    console.error('S3 upload URL error:', error);
    throw error;
  }
};

// Helper function to generate safe file keys
const generateFileKey = (userId, originalName, prefix = '') => {
  const timestamp = Date.now();
  const extension = path.extname(originalName);
  const baseName = path.basename(originalName, extension)
    .replace(/[^a-zA-Z0-9-_]/g, '-')
    .substring(0, 50);
  
  return `${prefix}${userId}/${timestamp}-${baseName}${extension}`;
};

module.exports = {
  uploadFile,
  getFile,
  deleteFile,
  listFiles,
  generatePresignedUrl,
  generateUploadUrl,
  generateFileKey,
  mockStorage // Export for testing
};
