variable "namespace" {
  description = "Kub namespace"
}

variable "app_name" {
  description = "Kub app name"
}

variable "environment" {
  description = "Kub environment"
}

variable "default_tags" {
  description = "Default tags"
}

locals {
    name = "${var.namespace}-${var.environment}-${var.app_name}"
    default_tags = {
    }
}