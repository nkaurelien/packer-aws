terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}


data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["learn-packer-linux-aws-redis"]
  }
}

variable "instance_name" {
  default = "ubuntu-redis-server"
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-security-group"
  description = "Allow SSH, and Redis traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH traffic"
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Redis traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outgoing traffic"
  }

  tags = {
    Name = "redis-server-security-group"
  }
}

# resource "aws_launch_configuration" "redis_lc" {
#   name            = "redis-launch-config-"
#   image_id        = data.aws_ami.this.id
#   instance_type   = "t2.micro"
#   # security_groups = [aws_security_group.redis_sg.name]

#   lifecycle {
#     create_before_destroy = true
#   }
# }



resource "aws_launch_template" "redis_lt" {
  name          = "redis-launch-template"
  image_id      = data.aws_ami.this.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.redis_sg.id]
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = var.instance_name
      Creator = "nkaurelien"
    }
  }
}

resource "aws_autoscaling_group" "redis_asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1
  # launch_configuration = aws_launch_configuration.redis_lc.name
  # vpc_zone_identifier = [for s in data.aws_subnet.this : s.id]
  vpc_zone_identifier = local.filtered_subnet_ids


  launch_template {
    id      = aws_launch_template.redis_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.instance_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Creator"
    value               = "nkaurelien"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.redis_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.redis_asg.name
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.redis_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.redis_asg.name
  }
}

output "ami_id" {
  value = data.aws_ami.this.id
}
