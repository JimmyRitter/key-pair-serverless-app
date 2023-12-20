const getHandler = require('./getHandler');
const postHandler = require('./postHandler');

exports.handler = async (event) => {
    switch (event.httpMethod) {
        case 'GET':
            return getHandler.handler(event);
        case 'POST':
            return postHandler.handler(event);
        default:
            return { statusCode: 400, body: JSON.stringify({ message: 'Invalid request method' }) };
    }
};
