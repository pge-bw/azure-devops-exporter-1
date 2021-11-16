provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {}

resource "aws_key_pair" "ado_exporter_build_access_key" {
  key_name   = "ado_exporter_build_access_key"
  public_key = "ssh-rsa <YOUR PUBLIC KEY HERE>"
}

data "aws_subnet_ids" "nat" {
  vpc_id = var.vpc_id
  tags = {
    network = "nat"
  }
}

resource "aws_security_group" "ado_exporter_build_sg" {
  name   = "ado_exporter_build_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "build_plugin_ec2" {
  ami                  = "ami-083654bd07b5da81d" # ubuntu 20.04 LTS release 20211021: https://cloud-images.ubuntu.com/locator/ec2/
  instance_type        = "t2.medium"
  key_name             = "ado_exporter_build_access_key"
  subnet_id            = element(tolist(data.aws_subnet_ids.nat.ids), 0)
  security_groups      = [aws_security_group.ado_exporter_build_sg.id]
  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }
  user_data = <<EOF
#! /bin/bash
sudo apt-get update && sudo apt-get install --yes awscli docker.io
sudo usermod -aG docker ubuntu
EOF
}

output "connection_string" {
  value = "ssh ubuntu@${aws_instance.build_plugin_ec2.private_ip}"
}
