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

#Kinesis Data Streams
resource "aws_kinesis_stream" "trades" {
  name             = "${var.name}-${local.environment}-trades"
  shard_count      = 1
  retention_period = 24

  tags = merge(var.default_tags, {
    Name        = "${var.name}-${local.environment}-trades"
  })
}

#S3
resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.unique_slug}-${var.name}-${local.environment}"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = merge(var.default_tags, {
    Name        = "${var.name}-${local.environment}-s3"
  })
}

#Kinesis Firehose Delivery
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "${var.name}-${local.environment}-trades"
  destination = "s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.trades.arn
    role_arn = aws_iam_role.firehose_role.arn
  }

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.data_lake.arn

    cloudwatch_logging_options {
      enabled = true
      log_group_name = "${var.name}-${local.environment}-trades-firehose"
      log_stream_name = "${var.name}-${local.environment}-trades-firehose"
    }
  }
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
}
