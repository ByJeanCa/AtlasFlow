terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "sg-web-ssh-http-dev" {
  
}