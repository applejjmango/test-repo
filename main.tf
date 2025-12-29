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
