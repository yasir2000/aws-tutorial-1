const AWS = require('aws-sdk');

// Configure AWS for local development
const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';

if (isOffline) {
  // Use in-memory mock for local development
  console.log('Using in-memory mock for DynamoDB operations');
  module.exports = require('./mockdb');
} else {
  // Use real AWS DynamoDB
  const config = {
    region: process.env.AWS_REGION || 'us-east-1',
  };

  AWS.config.update(config);
  const dynamoDB = new AWS.DynamoDB.DocumentClient();

  const getItem = async (tableName, key) => {
    const params = {
      TableName: tableName,
      Key: key,
    };

    const result = await dynamoDB.get(params).promise();
    return result.Item;
  };

  const put = async (tableName, item) => {
    const params = {
      TableName: tableName,
      Item: item,
    };

    await dynamoDB.put(params).promise();
    return item;
  };

  const updateItem = async (tableName, key, updateExpression, expressionAttributeValues, expressionAttributeNames) => {
    const params = {
      TableName: tableName,
      Key: key,
      UpdateExpression: updateExpression,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW',
    };

    if (expressionAttributeNames) {
      params.ExpressionAttributeNames = expressionAttributeNames;
    }

    const result = await dynamoDB.update(params).promise();
    return result.Attributes;
  };

  const deleteItem = async (tableName, key) => {
    const params = {
      TableName: tableName,
      Key: key,   
    };
    await dynamoDB.delete(params).promise();
  };

  const scan = async (tableName) => {
    const params = {
      TableName: tableName
    };
    const result = await dynamoDB.scan(params).promise();
    return result.Items;
  };

  module.exports = {
    getItem,
    put,
    updateItem,
    deleteItem,
    scan
  };
}