terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.24.1"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "web_app" {
  ami                    = ami-065efef2c739d613b
  subnet_id              = subnet-07918d2e3724f7d5f
  instance_type          = "t3.micro"
  user_data              = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name = $var.name-learn
  }
}
