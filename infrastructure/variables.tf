variable "region" {
  description = "The region where the resources will be deployed"
  type        = string
}

variable "my_ip" {
  description = "Personal ip"
  type        = list(string)
}

variable "common_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "Jeanca"
    Terraform   = "true"
    Group = "servers"

  }
}

variable "amis" {
  description = "List of amis available to use"
  type        = list(string)
}

variable "tfprofile" {
  description = "aws profile name"
  type        = string
}