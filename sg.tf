# 1. Virginia Security Group (Primary)
resource "aws_security_group" "primary_sg" {
  name        = "primary-sg-prod"
  description = "Security Group for Primary VPC (SSM & Peering)"
  vpc_id      = aws_vpc.primary.id
}

resource "aws_vpc_security_group_egress_rule" "primary_egress_all" {
  security_group_id = aws_security_group.primary_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "primary_ingress_local" {
  security_group_id = aws_security_group.primary_sg.id
  cidr_ipv4         = aws_vpc.primary.cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "primary_ingress_peer_icmp" {
  security_group_id = aws_security_group.primary_sg.id
  cidr_ipv4         = var.seoul_vpc_cidr
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
