variable "name" {
  description = "The name of your stack"
}

variable "environment" {
  description = "The name of your environment"
}

variable "default_tags" {
  description = "Default tags"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "public_subnets" {
  description = "List of public subnets"
}

variable "private_subnets" {
  description = "List of private subnets"
}

variable "availability_zones" {
  description = "List of availability zones"
}

locals {
    default_tags = {
    }
}

