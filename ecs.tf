resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  vpc_security_group_ids = [aws_security_group.ecs.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-ecs-asg"
  min_size            = var.desired_ec2_capacity
  max_size            = var.desired_ec2_capacity
  desired_capacity    = var.desired_ec2_capacity
  vpc_zone_identifier = [for subnet in aws_subnet.private_app : subnet.id]

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  health_check_type = "EC2"

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

locals {
  nginx_a_html = <<-HTML
    <!doctype html>
    <html>
    <head><title>nginx-a</title></head>
    <body>
      <h1>nginx-a</h1>
      <p>Response served by ECS service nginx-a.</p>
      <p>DevOps / IaC assignment demo.</p>
    </body>
    </html>
  HTML

  nginx_b_html = <<-HTML
    <!doctype html>
    <html>
    <head><title>nginx-b</title></head>
    <body>
      <h1>nginx-b</h1>
      <p>Response served by ECS service nginx-b.</p>
      <p>DevOps / IaC assignment demo.</p>
    </body>
    </html>
  HTML
}

resource "aws_ecs_task_definition" "nginx_a" {
  family                   = "${var.project_name}-nginx-a"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "nginx-a"
      image     = "nginx:alpine"
      essential = true
      cpu       = var.nginx_cpu
      memory    = var.nginx_memory

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      command = [
        "/bin/sh",
        "-c",
        "printf '%s' '${local.nginx_a_html}' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "nginx-a"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "nginx_b" {
  family                   = "${var.project_name}-nginx-b"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.nginx_cpu
  memory                   = var.nginx_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "nginx-b"
      image     = "nginx:alpine"
      essential = true
      cpu       = var.nginx_cpu
      memory    = var.nginx_memory

      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      command = [
        "/bin/sh",
        "-c",
        "printf '%s' '${local.nginx_b_html}' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "nginx-b"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "nginx_a" {
  name            = "${var.project_name}-nginx-a"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx_a.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_a.arn
    container_name   = "nginx-a"
    container_port   = 80
  }

  depends_on = [
    aws_autoscaling_group.ecs,
    aws_lb_listener.http
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_service" "nginx_b" {
  name            = "${var.project_name}-nginx-b"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx_b.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_b.arn
    container_name   = "nginx-b"
    container_port   = 80
  }

  depends_on = [
    aws_autoscaling_group.ecs,
    aws_lb_listener.http
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
