output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}