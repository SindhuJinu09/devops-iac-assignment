data "archive_file" "upload_lambda" {
  type        = "zip"
  source_file = "${path.module}/upload.py"
  output_path = "${path.module}/upload_lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-upload"
  retention_in_days = 7
}

resource "aws_lambda_function" "upload" {
  function_name    = "${var.project_name}-upload"
  role             = var.lambda_role_arn
  handler          = "upload.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256
  timeout          = 15
  memory_size      = 256
  environment {
    variables = {
      UPLOAD_BUCKET = var.upload_bucket_name
      MAX_BYTES     = "5242880"
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_apigatewayv2_api" "upload" {
  name          = "${var.project_name}-upload-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "upload" {
  api_id                 = aws_apigatewayv2_api.upload.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.upload.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.upload.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload.execution_arn}/*/*"
}
