output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Public ALB URL"
  value       = "http://${aws_lb.this.dns_name}/"
}

output "upload_api_url" {
  description = "Upload API endpoint"
  value       = "${aws_apigatewayv2_api.upload.api_endpoint}/upload"
}

output "upload_bucket_name" {
  description = "Private S3 upload bucket"
  value       = aws_s3_bucket.uploads.bucket
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_a" {
  value = aws_ecs_service.nginx_a.name
}

output "ecs_service_b" {
  value = aws_ecs_service.nginx_b.name
}

output "ecs_log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "vpc_id" {
  value = aws_vpc.this.id
}
