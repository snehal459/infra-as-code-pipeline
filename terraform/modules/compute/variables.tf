variable "cluster_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecr_image" {
  description = "ECR image URL"
  type        = string
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "ecs_sg_id" {
  description = "ECS Security Group ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}