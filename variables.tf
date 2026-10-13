variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kstpl-devops-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "VPC CIDR; this demo allocates six /24 subnets and therefore requires a /16 network."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = cidrnetmask(var.vpc_cidr) == "255.255.0.0"
    error_message = "vpc_cidr must be a valid /16 IPv4 network."
  }
}

variable "instance_type" {
  description = "ECS EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "desired_ec2_capacity" {
  description = "Number of ECS EC2 instances"
  type        = number
  default     = 1
}

variable "nginx_cpu" {
  description = "CPU units per nginx task"
  type        = number
  default     = 128
}

variable "nginx_memory" {
  description = "Memory MB per nginx task"
  type        = number
  default     = 256
}
