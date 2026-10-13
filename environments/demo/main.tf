module "networking" {
  source       = "../../modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "alb" {
  source            = "../../modules/alb"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.networking.alb_security_group_id
}

module "storage" {
  source       = "../../modules/storage"
  project_name = var.project_name
}

module "iam" {
  source           = "../../modules/iam"
  project_name     = var.project_name
  upload_bucket_arn = module.storage.bucket_arn
}

module "ecs" {
  source                    = "../../modules/ecs"
  project_name              = var.project_name
  aws_region                = var.aws_region
  instance_type             = var.instance_type
  desired_ec2_capacity      = var.desired_ec2_capacity
  nginx_cpu                 = var.nginx_cpu
  nginx_memory              = var.nginx_memory
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
  ecs_security_group_id     = module.networking.ecs_security_group_id
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn         = module.iam.ecs_task_role_arn
  target_group_a_arn        = module.alb.target_group_a_arn
  target_group_b_arn        = module.alb.target_group_b_arn
  depends_on                = [module.alb]
}

module "lambda" {
  source           = "../../modules/lambda"
  project_name     = var.project_name
  lambda_role_arn  = module.iam.lambda_role_arn
  upload_bucket_name = module.storage.bucket_name
}
