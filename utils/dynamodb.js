const AWS = require('aws-sdk');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const getItem = async (tableName, key) => {
  const params = {
    TableName: tableName,
    Key: key,
  };

  const result = await 
dynamoDB.get(params).promise();
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

const updateItem = async (tableName, key, updateExpression, expressionAttributeValues) => {
  const params = {
    TableName: tableName,
    Key: key,
    UpdateExpression: updateExpression,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW',
  };

  const deleteItem = async (tableName, key) => {
  const params = {
    TableName: tableName,
    Key: key,   
    };
    await dynamoDB.delete(params).promise();
};
  module.exports ={
    getItem,
    put,
    updateItem,
    deleteItem  }
};