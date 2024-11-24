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



variable "instance_name" {
  default = "ubuntu-redis-server"
}


data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["learn-packer-linux-aws-redis"]
  }

  #   filter {
  #     name   = "virtualization-type"
  #     values = ["hvm"]
  #   }

  #   filter {
  #     name   = "root-device-type"
  #     values = ["ebs"]
  #   }

}


resource "aws_security_group" "redis_sg" {
  name        = "webserver-security-group"
  description = "Allow HTTP, HTTPS, SSH, MySQL, PostgreSQL, and Redis traffic"


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

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.this.id
  instance_type = "t2.micro"

  security_groups = [aws_security_group.redis_sg.name]

  tags = {
    Name    = var.instance_name
    Creator = "nkaurelien"
  }

}

output "ami_id" {
  value = data.aws_ami.this.id
}

