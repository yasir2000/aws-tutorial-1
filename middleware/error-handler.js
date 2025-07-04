const logger = require('../utils/logger');
const { errorResponse } = require('../utils/response');

const errorHandler = (handler) => {
  return async (event, context) => {
    try {
      const result = await handler(event, context);
      return result;
    } catch (error) {
      logger.error('Unhandled error in Lambda function', {
        error: error.message,
        stack: error.stack,
        event: JSON.stringify(event)
      });

      if (error.name === 'ValidationError') {
        return errorResponse(error.message, 400);
      }

      if (error.name === 'UnauthorizedError') {
        return errorResponse('Unauthorized', 401);
      }

      if (error.name === 'ForbiddenError') {
        return errorResponse('Forbidden', 403);
      }

      if (error.name === 'NotFoundError') {
        return errorResponse('Resource not found', 404);
      }

      return errorResponse('Internal server error', 500);
    }
  };
};

module.exports = errorHandler;