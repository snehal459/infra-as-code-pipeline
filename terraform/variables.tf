variable "cluster_name" {}
variable "ecr_image" {}
variable "alb_sg_id" {}
variable "ecs_sg_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}