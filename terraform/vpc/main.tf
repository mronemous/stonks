/* IMPORTANT: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html */

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-vpc"
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-igw"
  })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.private_subnets)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-nat-${format("%03d", count.index+1)}"
  })
}

resource "aws_eip" "nat" {
  count = length(var.private_subnets)
  vpc = true

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-eip-${format("%03d", count.index+1)}"
  })
}


#Subnets
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.private_subnets)

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-private-subnet-${format("%03d", count.index+1)}"
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                      = "1"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-public-subnet-${format("%03d", count.index+1)}"
    "kubernetes.io/cluster/${var.name}-${var.environment}" = "shared",
    "kubernetes.io/role/elb"                               = "1"
  })
}

#Routing Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-routing-table-public"
  })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-routing-table-private-${format("%03d", count.index+1)}"
  })
}

resource "aws_route" "private" {
  count                  = length(compact(var.private_subnets))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

#Logging
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc-flow-logs-role.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc" {
  name              = "/aws/vpc/${var.name}-${var.environment}/flow"
  retention_in_days = 30

  tags = merge(var.default_tags, local.default_tags, {
    Name = "${var.name}-${var.environment}-vpc-cloudwatch-log-group"
  })
}
