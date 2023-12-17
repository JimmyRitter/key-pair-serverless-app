# Terraform & AWS Challenge: Deploy a Basic Serverless Application

## Objective
Deploy a simple serverless application using AWS Lambda, API Gateway, and DynamoDB. The application will be a basic API to store and retrieve key-value pairs.

## Components to Use
- **AWS Lambda**: Create a Lambda function that will handle API requests.
- **API Gateway**: Set up an API Gateway to trigger the Lambda function.
- **DynamoDB**: Use a DynamoDB table to store key-value pairs.
- **IAM Role**: Create an IAM role with policies that allow Lambda to access DynamoDB.

## Steps

### Setup AWS Environment
- Configure AWS CLI with your credentials.

### Terraform Setup
- Write Terraform configuration files to set up the above AWS resources.
- Use variables and outputs in Terraform for a clean and reusable code structure.

### Lambda Function
- Write a simple Lambda function in Python or Node.js.
- The function should be able to:
  - Add a key-value pair to the DynamoDB table.
  - Retrieve a value by key from the DynamoDB table.

### API Gateway
- Create REST API endpoints (GET and POST) that trigger the Lambda function.

### DynamoDB Table
- Create a DynamoDB table with a primary key.

### IAM Role and Policy
- Create an IAM role for the Lambda function.
- Attach policies to the IAM role that allow it to interact with DynamoDB.

### Terraform Apply
- Run `terraform apply` to deploy your infrastructure.

### Testing
- Test your API using tools like Postman or CURL.
- Check if data is being correctly added and retrieved from DynamoDB.

### Cleanup
- Once done, remember to destroy the resources using `terraform destroy` to avoid any unwanted charges.

## Learning Goals
- Understanding of serverless architecture.
- Hands-on experience with AWS Lambda, API Gateway, and DynamoDB.
- Practice with IAM roles and policies.
- Gain proficiency in writing and organizing Terraform code.
- Develop debugging and testing skills for cloud resources.
