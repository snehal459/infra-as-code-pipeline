output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "subnet_ids" {
  value = data.aws_subnets.existing.ids
}