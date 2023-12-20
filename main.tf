provider "aws" {
  region = var.aws_region
}

// BUCKET CREATION
// Create a random bucket name to avoid naming conflicts
resource "random_pet" "lambda_bucket_name" {
  prefix = "serverless-key-value-app"
  length = 4
}

// Create an S3 bucket with the random name on the step above
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

// Create a bucket ownership control to ensure that objects uploaded to the bucket are owned by the bucket owner
resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

// Create a bucket ACL to ensure that objects uploaded to the bucket are private
resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

# Create DynamoDB table
resource "aws_dynamodb_table" "key_value_table" {
  name           = "KeyValueTable" # Name your table
  billing_mode   = "PROVISIONED"   # Use provisioned billing mode
  hash_key       = "key"           # The hash key
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "key"
    type = "S" # 'S' for string type
  }
}

// LAMBDA FUNCTION CREATION
// Use "archive_file" to zip the lambda function code
data "archive_file" "lambda_key_value_app" {
  type        = "zip"

  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

// Upload the zip file to the S3 bucket
resource "aws_s3_object" "lambda_key_value_app" {
  bucket  = aws_s3_bucket.lambda_bucket.id

  key     = "functions.zip"
  source  = data.archive_file.lambda_key_value_app.output_path

  etag    = filemd5(data.archive_file.lambda_key_value_app.output_path)
}

// IAM Role for the Lambda Function
resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

// IAM Policy to Allow Lambda Function to Access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "IAM policy for accessing DynamoDB from Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Effect = "Allow",
        Resource = aws_dynamodb_table.key_value_table.arn
      },
    ],
  })
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

// Create the lambda function
resource "aws_lambda_function" "key_value_app" {
  function_name     = "KeyValueApp"

  s3_bucket         = aws_s3_bucket.lambda_bucket.id
  s3_key            = aws_s3_object.lambda_key_value_app.key

  runtime           = "nodejs16.x"
  handler           = "index.handler"

  source_code_hash  = data.archive_file.lambda_key_value_app.output_base64sha256

  role              = aws_iam_role.lambda_iam_role.arn
}

// MONITORING
// Create a CloudWatch log group for the lambda function
resource "aws_cloudwatch_log_group" "key_value_app" {
  name              = "/aws/lambda/${aws_lambda_function.key_value_app.function_name}"

  retention_in_days = 5
}

// API GATEWAY CREATION
// Create an API Gateway
resource "aws_apigatewayv2_api" "key_value_api" {
  name          = "KeyValueAPI"
  protocol_type = "HTTP"
}

# // Create an API Gateway stage (e.g: "Dev", "Staging", and "Production")
resource "aws_apigatewayv2_stage" "key_value_stage" {
  api_id = aws_apigatewayv2_api.key_value_api.id

  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

// Create a CloudWatch log group for the API Gateway
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.key_value_api.name}"

  retention_in_days = 5
}


// Configures the API Gateway to use the Lambda function.
resource "aws_apigatewayv2_integration" "key_value_integration" {
  api_id = aws_apigatewayv2_api.key_value_api.id

  integration_uri    = aws_lambda_function.key_value_app.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

// Create an API Gateway route
resource "aws_apigatewayv2_route" "key_value_get_route" {
  api_id    = aws_apigatewayv2_api.key_value_api.id
  route_key = "GET /keyvalue"
  target    = "integrations/${aws_apigatewayv2_integration.key_value_integration.id}"
}

resource "aws_apigatewayv2_route" "key_value_post_route" {
  api_id    = aws_apigatewayv2_api.key_value_api.id
  route_key = "POST /keyvalue"
  target    = "integrations/${aws_apigatewayv2_integration.key_value_integration.id}"
}

resource "aws_lambda_permission" "key_value_api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.key_value_app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.key_value_api.execution_arn}/*/*"
}