module "networking" {
  source = "../../modules/networking"
}

module "security" {
  source = "../../modules/security"

  vpc_id = module.networking.vpc_id
}

module "compute" {
  source = "../../modules/compute"

  cluster_name = "my-cluster"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.subnet_ids

  ecs_sg_id = module.security.ecs_sg_id
  alb_sg_id = module.security.alb_sg_id

  ecr_image  = var.ecr_image
}

module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name   = "my-cluster"
  service_name   = "my-service"
  alb_arn_suffix = module.compute.alb_arn_suffix
}