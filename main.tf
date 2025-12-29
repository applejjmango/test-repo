resource "aws_vpc" "primary" {
  cidr_block           = var.va_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-va-vpc"
  }
}

resource "aws_internet_gateway" "primary_igw" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "primary_igw"
  }
}

resource "aws_subnet" "primary_public" {
  count                   = length(var.va_public_subnets)
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = var.va_public_subnets[count.index]
  availability_zone       = var.va_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-va-pub-${var.va_azs[count.index]}"
  }
}

resource "aws_subnet" "primary_private" {
  count             = length(var.va_private_subnets)
  vpc_id            = aws_vpc.primary.id
  cidr_block        = var.va_private_subnets[count.index]
  availability_zone = var.va_azs[count.index]

  tags = {
    Name = "dev-va-private-${var.va_azs[count.index]}"
  }
}

resource "aws_eip" "primary_eip" {
  count  = length(var.va_public_subnets)
  domain = "vpc"

  tags = {
    Name = "dev-va-nat-eip-${var.va_azs[count.index]}"
  }
}

resource "aws_nat_gateway" "primary_nat" {
  count         = length(var.va_public_subnets)
  allocation_id = aws_eip.primary_eip[count.index].id
  subnet_id     = aws_subnet.primary_public[count.index].id

  tags = {
    Name = "dev-va-nat-${var.va_azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.primary_igw]
}

resource "aws_route_table" "primary_public_rt" {
  vpc_id = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name = "dev-va-pub-rt"
  }
}

resource "aws_route_table_association" "primary_public_rta" {
  count          = length(var.va_public_subnets)
  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public_rt.id
}

resource "aws_route_table" "primary_private_rt" {
  count  = length(var.va_private_subnets)
  vpc_id = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.primary_nat[count.index].id
  }

  tags = {
    Name = "dev-va-priv-rt-${var.va_azs[count.index]}"
  }
}

resource "aws_route_table_association" "primary_private_rta" {
  count          = length(var.va_private_subnets)
  subnet_id      = aws_subnet.primary_private[count.index].id
  route_table_id = aws_route_table.primary_private_rt[count.index].id
}

# -----------------------------------------------------------------------------
# 2. Seoul Network (Secondary)
# -----------------------------------------------------------------------------
resource "aws_vpc" "secondary" {
  provider             = aws.seoul
  cidr_block           = var.seoul_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-seoul-vpc"
  }
}

resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.seoul
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name = "dev-seoul-igw"
  }
}

resource "aws_subnet" "secondary_public" {
  provider                = aws.seoul
  count                   = length(var.seoul_public_subnets)
  vpc_id                  = aws_vpc.secondary.id
  cidr_block              = var.seoul_public_subnets[count.index]
  availability_zone       = var.seoul_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-seoul-pub-${var.seoul_azs[count.index]}"
  }
}

resource "aws_subnet" "secondary_private" {
  provider          = aws.seoul
  count             = length(var.seoul_private_subnets)
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = var.seoul_private_subnets[count.index]
  availability_zone = var.seoul_azs[count.index]

  tags = {
    Name = "dev-seoul-priv-${var.seoul_azs[count.index]}"
  }
}
