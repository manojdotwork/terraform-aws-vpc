/*====
The VPC
======*/
data "aws_availability_zones" "zones" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge({ "Name" = "${var.identifier}-vpc" }, var.default_tags)
}

/*====
Subnets
======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Name" = "${var.identifier}-igw" }, var.default_tags)
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc   = true
  count = 2
  tags  = merge({ "Name" = "${var.identifier}-eip" }, var.default_tags)
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
  count         = 2
  tags          = merge({ "Name" = "${var.identifier}-nat" }, var.default_tags)
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = 2
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = element(data.aws_availability_zones.zones.names.*, count.index)
  map_public_ip_on_launch = true

  tags = merge({ "Name" = "${var.identifier}-public-subnet" }, var.default_tags)
}

/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = 2
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone       = element(data.aws_availability_zones.zones.names.*, count.index)
  map_public_ip_on_launch = false

  tags = merge({ "Name" = "${var.identifier}-private-subnet" }, var.default_tags)
}

/* Routing table for private subnets */
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Name" = "${var.identifier}-private-route-table" }, var.default_tags)
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Name" = "${var.identifier}-public-route-table" }, var.default_tags)
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway" {
  count                  = 2
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

/*====
VPC's Default Security Group
======*/
resource "aws_security_group" "private" {
  name        = "${var.identifier}-private-sg"
  description = "Allow all traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    #self      = true
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = "${var.identifier}-private-sg" }, var.default_tags)
}

resource "aws_security_group" "public" {
  name        = "${var.identifier}-public-sg"
  description = "All traffic from internet over ports 80,443 and from private SG"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    security_groups = [aws_security_group.private.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge({ "Name" = "${var.identifier}-public-sg" }, var.default_tags)
}

