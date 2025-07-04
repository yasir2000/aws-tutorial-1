const { successResponse, errorResponse } = require('../utils/response');
const AWS = require('aws-sdk');

module.exports.check = async (event) => {
  try {
    const checks = {
      dynamodb: await checkDynamoDB(),
      sns: await checkSNS(),
      sqs: await checkSQS(),
      timestamp: new Date().toISOString()
    };

    const allHealthy = Object.values(checks).every(check => 
      typeof check === 'boolean' ? check : check.healthy
    );

    return successResponse({
      status: allHealthy ? 'healthy' : 'unhealthy',
      checks
    });
  } catch (error) {
    return errorResponse(error.message);
  }
};

const checkDynamoDB = async () => {
  try {
    const dynamoDb = new AWS.DynamoDB();
    await dynamoDb.describeTable({ TableName: process.env.USERS_TABLE }).promise();
    return { healthy: true, service: 'DynamoDB' };
  } catch (error) {
    return { healthy: false, service: 'DynamoDB', error: error.message };
  }
};

const checkSNS = async () => {
  try {
    const sns = new AWS.SNS();
    await sns.listTopics().promise();
    return { healthy: true, service: 'SNS' };
  } catch (error) {
    return { healthy: false, service: 'SNS', error: error.message };
  }
};

const checkSQS = async () => {
  try {
    const sqs = new AWS.SQS();
    await sqs.listQueues().promise();
    return { healthy: true, service: 'SQS' };
  } catch (error) {
    return { healthy: false, service: 'SQS', error: error.message };
  }
};
