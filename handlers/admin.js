const { successResponse, errorResponse } = require('../utils/response');
const { extractUserFromEvent } = require('../utils/auth');
const { getItem, put, updateItem } = require('../utils/dynamodb');
const AWS = require('aws-sdk');

const dynamoDb = new AWS.DynamoDB.DocumentClient();

// Admin-only endpoint to get system stats
module.exports.getStats = async (event) => {
  try {
    const currentUser = extractUserFromEvent(event);
    
    // Check if user has admin role (you can customize this logic)
    if (!currentUser.username.includes('admin')) {
      return errorResponse('Admin access required', 403);
    }

    const stats = {
      users: await getTableCount(process.env.USERS_TABLE),
      products: await getTableCount(process.env.PRODUCTS_TABLE),
      orders: await getTableCount(process.env.ORDERS_TABLE),
      timestamp: new Date().toISOString()
    };

    return successResponse(stats);
  } catch (error) {
    return errorResponse(error.message);
  }
};

const getTableCount = async (tableName) => {
  const params = {
    TableName: tableName,
    Select: 'COUNT'
  };

  const result = await dynamoDb.scan(params).promise();
  return result.Count;
};
// Admin-only endpoint to reset the database