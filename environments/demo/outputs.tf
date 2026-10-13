output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = module.alb.dns_name
}
output "alb_url" {
  description = "Public ALB URL"
  value       = module.alb.url
}
output "upload_api_url" {
  description = "Upload API endpoint"
  value       = module.lambda.upload_api_url
}
output "upload_bucket_name" {
  description = "Private S3 upload bucket"
  value       = module.storage.bucket_name
}
output "ecs_cluster_name" { value = module.ecs.cluster_name }
output "ecs_service_a" { value = module.ecs.service_a_name }
output "ecs_service_b" { value = module.ecs.service_b_name }
output "ecs_log_group_name" { value = module.ecs.log_group_name }
output "lambda_log_group_name" { value = module.lambda.log_group_name }
output "vpc_id" { value = module.networking.vpc_id }
