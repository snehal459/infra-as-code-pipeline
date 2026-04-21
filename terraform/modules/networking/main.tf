# Use existing default VPC
data "aws_vpc" "existing" {
  default = true
}

# Get all subnets from that VPC
data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

