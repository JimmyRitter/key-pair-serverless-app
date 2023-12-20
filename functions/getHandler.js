const AWS = require("aws-sdk");
const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    // Handle GET request
    const params = {
      TableName: "KeyValueTable",
      Key: {
        key: event.queryStringParameters.key
      },
    };
    const data = await dynamoDb.get(params).promise();
    return { statusCode: 200, body: JSON.stringify(data.Item) };
  } catch (error) {
    return { statusCode: 500, body: JSON.stringify(error) };
  }
};
