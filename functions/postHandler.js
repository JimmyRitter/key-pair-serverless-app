const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    // Parse the JSON body from the event
    const requestBody = JSON.parse(event.body);

    // Handle POST request
    const params = {
        TableName: "KeyValueTable",
        Item: {
            key: requestBody.key,
            value: requestBody.value
        }
    };
    await dynamoDb.put(params).promise();
    return { statusCode: 200, body: JSON.stringify({ message: 'Data stored' }) };
};
