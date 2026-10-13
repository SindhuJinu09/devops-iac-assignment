output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_a_name" { value = aws_ecs_service.nginx_a.name }
output "service_b_name" { value = aws_ecs_service.nginx_b.name }
output "log_group_name" { value = aws_cloudwatch_log_group.ecs.name }
