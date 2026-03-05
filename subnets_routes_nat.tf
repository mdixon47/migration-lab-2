# Two public subnets (ALB requirement for internet-facing ALB). :contentReference[oaicite:4]{index=4}
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.public_subnet_azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-public-${count.index + 1}"
    Host = "n/a"
  })
}

# Single private subnet for the source server
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.private_subnet_az
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-private-1"
    Host = "source-server"
  })
}

# Public route table: 0.0.0.0/0 -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-rt-public"
    Host = "n/a"
  })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT in public subnet #1 (keeps NAT simple and cheap for the lab)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-nat-eip"
    Host = "n/a"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-nat"
    Host = "n/a"
  })

  depends_on = [aws_internet_gateway.igw]
}

# Private route table: 0.0.0.0/0 -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-rt-private"
    Host = "source-server"
  })
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
