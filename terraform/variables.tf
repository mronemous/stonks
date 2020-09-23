variable "name" {
  description = "the name of your stack"
  default     = "stonks"
}

variable "unique_slug" {
  description = "unique slug for s3 bucket prefix"
  default     = "714401593749" #using account for now
}

variable "default_tags" {
    type = map
    default = {
        Environment = "dev"
    }
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both private_subnets and public_subnets have to be defined as well"
  #default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "a list of CIDRs for private subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  #default     = ["10.0.0.0/20", "10.0.32.0/20", "10.0.64.0/20"]
  default     = ["10.0.0.0/20", "10.0.32.0/20"]
}

variable "public_subnets" {
  description = "a list of CIDRs for public subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  #default     = ["10.0.16.0/20", "10.0.48.0/20", "10.0.80.0/20"]
  default     = ["10.0.16.0/20", "10.0.48.0/20"]
}

variable "kubeconfig_path" {
  description = "Path where the config file for kubectl should be written to"
  default     = "~/.kube"
}

variable "k8s_version" {
  default = "1.17"
}

locals {
    environment = var.default_tags.Environment
    secrets = jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)
}
