terraform {
  required_version = ">= 0.13"
   backend "s3" {
    profile = "stonks-dev"
    bucket = "714401593749-stonks-dev-terraform"
    key    = "stonks-state"
    region = "us-east-1"
  }
}
#TODO: Need to encrypt this state store. Currently only in a private bucket.

provider "aws" {
  version = "~> 3.4.0"
  profile = "stonks-dev"
  region  = var.region
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  environment        = local.environment
  default_tags       = var.default_tags
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}

module "eks" {
  source          = "./eks"
  name            = var.name
  environment     = local.environment
  default_tags    = var.default_tags
  region          = var.region
  k8s_version     = var.k8s_version
  vpc_id          = module.vpc.id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  kubeconfig_path = var.kubeconfig_path
  secrets = local.secrets
}

#ECR Repos
module "ecr-sample-app" {
  source             = "./ecr"
  namespace          = var.name
  environment        = local.environment
  app_name           = "sample-app"
  default_tags       = var.default_tags
}

module "ecr-trade-ingest-app" {
  source             = "./ecr"
  namespace          = var.name
  environment        = local.environment
  app_name           = "trade-ingest-app"
  default_tags       = var.default_tags
}

module "ecr-validator-app" {
  source             = "./ecr"
  namespace          = var.name
  environment        = local.environment
  app_name           = "validator-app"
  default_tags       = var.default_tags
}

#Secrets Store
resource "aws_secretsmanager_secret" "main" {
  name = "${var.name}-${local.environment}"

  tags = merge(var.default_tags, {
    Name        = "${var.name}-${local.environment}-secret"
  })
}
data "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.name

  depends_on = [aws_secretsmanager_secret.main]
}

data "archive_file" "lambda" {
 type = "zip"
 source_dir = "../src/lambdas"
 output_path = "../.build/lambdas.zip"
}