terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_instance" "web-container-instance" {
  ami           = var.amis[0]
  instance_type = "t3.micro"
  key_name      = "test" #This is in case you want to use a key already created in AWS. If not, create it using resource_key_pair.\\

  vpc_security_group_ids      = [aws_security_group.sg-web-ssh-http-dev.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = merge(
    var.common_tags, {
      Name = format("web-container-instance-%s", var.region)
    }
  )
}