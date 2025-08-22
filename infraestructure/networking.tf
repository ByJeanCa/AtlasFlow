module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    name = format("vpc-web-dev", var.region)

    cidr = "10.0.0.0/24"

    private_subnets = ["10.0.1.0/26", "10.0.2.0/26"]
    public_subnets = ["10.0.3.0/26", "10.0.4.0/26"]

    enable_nat_gateway = true

    tags = var.common_tags
}

resource "aws_security_group" "sg-web-ssh-http-dev" {
    name = format("sg-web-ssh-http", var.region)
    vpc_id = module.vpc.vpc_id

    ingress {
        description = "Allow ssh access to my ip"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.my_ip
    }

    ingress {
        description = "Allow http free access"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = var.common_tags
}