resource "aws_iam_role" "role" {
  name = "role"
  managed_policy_arns = [
    aws_iam_policy.policy.arn
  ]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "policy"
  description = "My policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-2:703866956858:*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-2:703866956858:log-group:/aws/lambda/test-function:*"
      },
    ]
  })
}

data "archive_file" "python_lambda_package" {  
  type = "zip"  
  source_file = "${path.module}/code/function.py" 
  output_path = "${path.module}/code/function.zip"
}

resource "aws_lambda_function" "api_function" {
        function_name = "API_Implementation"
        filename      = "${path.module}/code/function.zip"
        source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
        role          = aws_iam_role.role.arn
        runtime       = "python3.8"
        handler       = "function.lambda_handler"
        timeout       = 10
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-2:703866956858:1vjh7nd8k5/*/*/test"
}