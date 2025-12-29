resource "aws_instance" "primary_ec2" {
  count                  = length(var.va_private_subnets)
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.va_ami.id
  subnet_id              = aws_subnet.primary_private[count.index].id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
}

resource "aws_instance" "secondary_ec2" {
  count                  = length(var.seoul_private_subnets)
  provider               = aws.seoul
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.seoul_ami.id
  subnet_id              = aws_subnet.secondary_private[count.index].id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
}
