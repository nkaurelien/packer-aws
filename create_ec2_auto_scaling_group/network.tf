data "aws_subnets" "this" {
  # filter {
  #   name   = "vpc-id"
  #   values = [""]
  # }
}

data "aws_subnet" "this" {
  for_each = toset(data.aws_subnets.this.ids)
  id       = each.value
}

locals {
  supported_azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  filtered_subnet_ids = [
    for subnet in data.aws_subnet.this : subnet.id
    if contains(local.supported_azs, subnet.availability_zone)
  ]
}

