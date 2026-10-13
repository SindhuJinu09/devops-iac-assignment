output "ecs_instance_profile_name" { value = aws_iam_instance_profile.ecs_instance.name }
output "ecs_task_execution_role_arn" { value = aws_iam_role.ecs_task_execution.arn }
output "ecs_task_role_arn" { value = aws_iam_role.ecs_task.arn }
output "lambda_role_arn" { value = aws_iam_role.lambda.arn }
