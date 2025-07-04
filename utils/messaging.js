const AWS = require('aws-sdk');
const sns = new AWS.SNS();
const sqs = new AWS.SQS();

const publishEvent = async (eventType, data) => {
    const message = {
        eventType,
        data,
        timestamp: new Date().toISOString()
    };

    const params = {
        TopicArn: `arn:aws:sns:${process.env.AWS_REGION}:${process.env.AWS_ACCOUNT_ID}:${process.env.SNS_TOPIC}`,
        Message: JSON.stringify(message),
        Subject: eventType
    };
    await sns.publish(params).promise();
};

const sendNotification = async(message) => {
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

// This code provides functions to publish events to an SNS topic and send notifications to an SQS queue.