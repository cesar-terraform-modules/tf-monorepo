terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  azs_map     = { for idx, az in local.azs : idx => az }
  subnet_bits = ceil(log(var.az_count * 2, 2))

  subnet_cidrs = try(
    [for i in range(var.az_count * 2) : cidrsubnet(var.cidr, local.subnet_bits, i)],
    null
  )

  public_subnet_cidrs  = local.subnet_cidrs == null ? [] : slice(local.subnet_cidrs, 0, var.az_count)
  private_subnet_cidrs = local.subnet_cidrs == null ? [] : slice(local.subnet_cidrs, var.az_count, var.az_count * 2)

  default_sg_egress_cidr_blocks = length(var.default_sg_egress_cidr_blocks) > 0 ? var.default_sg_egress_cidr_blocks : [var.cidr]
  default_sg_egress_ipv6_blocks = var.default_sg_egress_ipv6_cidr_blocks
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = "networking-basics"
    },
    var.tags
  )

  lifecycle {
    precondition {
      condition     = length(local.azs) == var.az_count
      error_message = "Not enough availability zones to satisfy az_count."
    }

    precondition {
      condition     = local.subnet_cidrs != null
      error_message = "CIDR block is too small to allocate public and private subnets."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "networking-basics-igw"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  for_each = local.azs_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[tonumber(each.key)]
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "public-${each.value}"
      Tier = "public"
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  for_each = local.azs_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[tonumber(each.key)]
  availability_zone = each.value

  tags = merge(
    {
      Name = "private-${each.value}"
      Tier = "private"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "public"
      Tier = "public"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = var.create_nat_gateway ? aws_subnet.public : {}

  domain = "vpc"

  tags = merge(
    {
      Name = "nat-eip-${each.value.availability_zone}"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway ? aws_subnet.public : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    {
      Name = "nat-${each.value.availability_zone}"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.create_nat_gateway ? [true] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[each.key].id
    }
  }

  tags = merge(
    {
      Name = "private-${each.value.availability_zone}"
      Tier = "private"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix       = "/aws/vpc/networking-basics-"
  retention_in_days = var.flow_logs_retention_in_days
  kms_key_id        = null
  skip_destroy      = false
  tags              = merge({ Name = "networking-basics-flow-logs" }, var.tags)
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "networking-basics-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "networking-basics-flow-logs-"
  role        = aws_iam_role.flow_logs[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn         = aws_iam_role.flow_logs[count.index].arn
  log_destination      = aws_cloudwatch_log_group.flow_logs[count.index].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = var.flow_logs_traffic_type
  vpc_id               = aws_vpc.this.id

  depends_on = [aws_iam_role_policy.flow_logs]
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  egress {
    description      = "Restrict outbound traffic to allowed CIDRs"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.default_sg_egress_cidr_blocks
    ipv6_cidr_blocks = local.default_sg_egress_ipv6_blocks
  }

  tags = merge(
    {
      Name = "default"
    },
    var.tags
  )
}
