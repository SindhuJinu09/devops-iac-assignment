output "upload_api_url" { value = "${aws_apigatewayv2_api.upload.api_endpoint}/upload" }
output "log_group_name" { value = aws_cloudwatch_log_group.lambda.name }
