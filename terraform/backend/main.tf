resource "aws_dynamodb_table" "webcounter" {
  name = var.dynamodb_table_name
  hash_key = "id"
  
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_resume_role" {
  name = "lambda_resume_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execute_lambda" {
  role = aws_iam_role.lambda_resume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_access_ddb_policy" {
  name = "lambda_access_ddb_policy"
  description = "Allows lambda function the access to the DynamoDB webcounter table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "DynamoDB:GetItem",
          "DynamoDB:UpdateItem",
          "DynamoDB:PutItem"
        ]
        Resource = aws_dynamodb_table.webcounter.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_access_ddb_policy" {
  role = aws_iam_role.lambda_resume_role.name
  policy_arn = aws_iam_policy.lambda_access_ddb_policy.arn
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_dir = "${path.module}/lambda-code"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "webcounter_api" {
  filename = data.archive_file.lambda_zip.output_path
  function_name = var.lambda_webcounter_update
  role = aws_iam_role.lambda_resume_role.arn
  handler = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.webcounter.name
    }
  }
}

resource "aws_apigatewayv2_api" "resume_api" {
  name = "cloud-resume-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = [
      "https://${var.custom_domain_name}", 
      "https://www.${var.custom_domain_name}",
      "http://localhost:5500",
      "http://127.0.0.1:5500"
    ]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age = 300
  }
}

resource "aws_apigatewayv2_route" "counter_route" {
  api_id = aws_apigatewayv2_api.resume_api.id
  route_key = "GET /get-count"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.resume_api.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description = "Resume counter lambda integration"
  integration_method = "POST"
  integration_uri = aws_lambda_function.webcounter_api.arn
  payload_format_version = "2.0"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webcounter_api.function_name
  principal = "apigateway.amazonaws.com" 
  source_arn = "${aws_apigatewayv2_api.resume_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id = aws_apigatewayv2_api.resume_api.id
  name = "$default"
  auto_deploy = true
}

output "api_endpoint" {
  description = "Base URL for your resume visitor counter API"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}
