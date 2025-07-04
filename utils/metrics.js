const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

const putMetric = async (metricName, value, unit = 'Count', namespace = 'CrudMicroservices') => {
  const params = {
    Namespace: namespace,
    MetricData: [
      {
        MetricName: metricName,
        Value: value,
        Unit: unit,
        Timestamp: new Date()
      }
    ]
  };

  try {
    await cloudwatch.putMetricData(params).promise();
  } catch (error) {
    console.error('Error putting metric:', error);
  }
};

const incrementCounter = async (metricName, value = 1) => {
  await putMetric(metricName, value, 'Count');
};

const recordLatency = async (metricName, latency) => {
  await putMetric(metricName, latency, 'Milliseconds');
};

module.exports = {
  putMetric,
  incrementCounter,
  recordLatency
};