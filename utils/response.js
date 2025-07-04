
const createResponse = (statusCode, body, headers = {}) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
    ...headers,
  },
  body: JSON.stringify(body),
});

const successResponse = (data) =>
  createResponse(200, { success: true, data });

const createdResponse = (data) =>
  createResponse(201, { success: true, data });

const errorResponse = (message, statusCode = 500) =>
  createResponse(statusCode, { success: false, message });

module.exports = {
  createResponse,
  successResponse,
  createdResponse,
  errorResponse,
};


