output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for subnet in aws_subnet.public : subnet.id] }
output "private_app_subnet_ids" { value = [for subnet in aws_subnet.private_app : subnet.id] }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "ecs_security_group_id" { value = aws_security_group.ecs.id }
