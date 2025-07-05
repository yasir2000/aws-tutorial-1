const { successResponse, errorResponse } = require('../utils/response');
const { uploadFile, getFile, deleteFile, listFiles, generateUploadUrl, generateFileKey } = require('../utils/s3');
const { extractUserFromEvent } = require('../utils/extractUser');

// Upload file endpoint
const upload = async (event) => {
  try {
    // Extract user from JWT token
    const user = extractUserFromEvent(event);
    if (!user) {
      return errorResponse(401, 'Unauthorized', 'AUTH_REQUIRED');
    }

    const body = JSON.parse(event.body || '{}');
    const { fileName, fileContent, contentType, metadata = {} } = body;

    if (!fileName || !fileContent) {
      return errorResponse(400, 'fileName and fileContent are required', 'MISSING_FIELDS');
    }

    // Generate a unique file key
    const fileKey = generateFileKey(user.userId, fileName, 'uploads/');

    // Convert base64 content to buffer if needed
    let fileBuffer;
    if (typeof fileContent === 'string') {
      // Assume base64 encoded content
      fileBuffer = Buffer.from(fileContent, 'base64');
    } else {
      fileBuffer = fileContent;
    }

    // Add user metadata
    const fileMetadata = {
      ...metadata,
      uploadedBy: user.userId,
      uploadedAt: new Date().toISOString(),
      originalName: fileName
    };

    const result = await uploadFile(
      fileKey,
      fileBuffer,
      contentType || 'application/octet-stream',
      fileMetadata
    );

    return successResponse({
      message: 'File uploaded successfully',
      file: {
        key: fileKey,
        originalName: fileName,
        location: result.Location,
        bucket: result.Bucket,
        contentType: contentType || 'application/octet-stream',
        uploadedBy: user.userId,
        uploadedAt: fileMetadata.uploadedAt
      }
    });

  } catch (error) {
    console.error('Upload error:', error);
    return errorResponse(500, 'Failed to upload file', 'UPLOAD_ERROR', error.message);
  }
};

// Get file endpoint
const getFileHandler = async (event) => {
  try {
    const { key } = event.pathParameters || {};

    if (!key) {
      return errorResponse(400, 'File key is required', 'MISSING_KEY');
    }

    // Extract user for authorization (optional, you can make this public if needed)
    const user = extractUserFromEvent(event);
    if (!user) {
      return errorResponse(401, 'Unauthorized', 'AUTH_REQUIRED');
    }

    const file = await getFile(key);

    // Convert buffer to base64 for JSON response
    const base64Content = file.Body.toString('base64');

    return successResponse({
      key,
      content: base64Content,
      contentType: file.ContentType,
      metadata: file.Metadata,
      lastModified: file.LastModified
    });

  } catch (error) {
    console.error('Get file error:', error);
    if (error.message.includes('not found') || error.code === 'NoSuchKey') {
      return errorResponse(404, 'File not found', 'FILE_NOT_FOUND');
    }
    return errorResponse(500, 'Failed to get file', 'GET_FILE_ERROR', error.message);
  }
};

// List files endpoint
const listFilesHandler = async (event) => {
  try {
    // Extract user for authorization
    const user = extractUserFromEvent(event);
    if (!user) {
      return errorResponse(401, 'Unauthorized', 'AUTH_REQUIRED');
    }

    const queryParams = event.queryStringParameters || {};
    const { prefix = '', maxKeys = '100', userOnly = 'false' } = queryParams;

    // If userOnly is true, filter by user's files
    const searchPrefix = userOnly === 'true' ? `uploads/${user.userId}/` : prefix;
    const maxKeysInt = Math.min(parseInt(maxKeys, 10) || 100, 1000);

    const result = await listFiles(searchPrefix, maxKeysInt);

    const files = result.Contents.map(file => ({
      key: file.Key,
      lastModified: file.LastModified,
      size: file.Size,
      etag: file.ETag,
      storageClass: file.StorageClass
    }));

    return successResponse({
      files,
      count: files.length,
      isTruncated: result.IsTruncated,
      prefix: searchPrefix
    });

  } catch (error) {
    console.error('List files error:', error);
    return errorResponse(500, 'Failed to list files', 'LIST_FILES_ERROR', error.message);
  }
};

// Delete file endpoint
const deleteFileHandler = async (event) => {
  try {
    const { key } = event.pathParameters || {};

    if (!key) {
      return errorResponse(400, 'File key is required', 'MISSING_KEY');
    }

    // Extract user for authorization
    const user = extractUserFromEvent(event);
    if (!user) {
      return errorResponse(401, 'Unauthorized', 'AUTH_REQUIRED');
    }

    // Check if user can delete this file (should be their own file)
    if (!key.startsWith(`uploads/${user.userId}/`)) {
      return errorResponse(403, 'You can only delete your own files', 'ACCESS_DENIED');
    }

    await deleteFile(key);

    return successResponse({
      message: 'File deleted successfully',
      key
    });

  } catch (error) {
    console.error('Delete file error:', error);
    if (error.message.includes('not found') || error.code === 'NoSuchKey') {
      return errorResponse(404, 'File not found', 'FILE_NOT_FOUND');
    }
    return errorResponse(500, 'Failed to delete file', 'DELETE_FILE_ERROR', error.message);
  }
};

// Generate presigned upload URL endpoint
const generateUploadUrlHandler = async (event) => {
  try {
    // Extract user for authorization
    const user = extractUserFromEvent(event);
    if (!user) {
      return errorResponse(401, 'Unauthorized', 'AUTH_REQUIRED');
    }

    const body = JSON.parse(event.body || '{}');
    const { fileName, contentType, expiresIn = 3600 } = body;

    if (!fileName) {
      return errorResponse(400, 'fileName is required', 'MISSING_FILENAME');
    }

    // Generate a unique file key
    const fileKey = generateFileKey(user.userId, fileName, 'uploads/');

    const result = await generateUploadUrl(
      fileKey,
      contentType || 'application/octet-stream',
      parseInt(expiresIn, 10)
    );

    return successResponse({
      uploadUrl: result.uploadUrl,
      key: fileKey,
      bucket: result.bucket,
      expiresIn: parseInt(expiresIn, 10),
      fileName,
      contentType: contentType || 'application/octet-stream'
    });

  } catch (error) {
    console.error('Generate upload URL error:', error);
    return errorResponse(500, 'Failed to generate upload URL', 'UPLOAD_URL_ERROR', error.message);
  }
};

module.exports = {
  upload,
  getFile: getFileHandler,
  listFiles: listFilesHandler,
  deleteFile: deleteFileHandler,
  generateUploadUrl: generateUploadUrlHandler
};
