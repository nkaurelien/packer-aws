output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.this : s.cidr_block]
}

output "subnet_ids" {
  value = values(data.aws_subnet.this)[*].id
}

output "filtered_subnet_ids" {
  value = local.filtered_subnet_ids
}

output "security_group_id" {
  value = aws_security_group.redis_sg.id
}

output "autoscaling_group_arn" {
  value = aws_autoscaling_group.redis_asg.arn
}

output "autoscaling_group_load_balancers" {
  value = aws_autoscaling_group.redis_asg.load_balancers
}
