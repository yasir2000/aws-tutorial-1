const AWS = require('aws-sdk');

// Configure for local development
const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';

let sns, sqs;

if (!isOffline) {
  sns = new AWS.SNS();
  sqs = new AWS.SQS();
}

const publishEvent = async (eventType, data) => {
    const message = {
        eventType,
        data,
        timestamp: new Date().toISOString()
    };

    if (isOffline) {
        console.log('MOCK SNS: Publishing event:', eventType, JSON.stringify(message, null, 2));
        return; // Just log for local development
    }

    const params = {
        TopicArn: `arn:aws:sns:${process.env.AWS_REGION}:${process.env.AWS_ACCOUNT_ID}:${process.env.SNS_TOPIC}`,
        Message: JSON.stringify(message),
        Subject: eventType
    };
    await sns.publish(params).promise();
};

const sendNotification = async(message) => {
    if (isOffline) {
        console.log('MOCK SQS: Sending notification:', JSON.stringify(message, null, 2));
        return; // Just log for local development
    }

    const params = {
        QueueUrl: `https://sqs.${process.env.AWS_REGION}.amazonaws.com/${process.env.AWS_ACCOUNT_ID}/${process.env.SQS_QUEUE}`,
        MessageBody: JSON.stringify(message)
    };

    await sqs.sendMessage(params).promise();
};

module.exports = {
    publishEvent,
    sendNotification
};