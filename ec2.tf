resource "aws_instance" "primary_ec2" {
  count                  = length(var.va_private_subnets)
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.va_ami.id
  subnet_id              = aws_subnet.primary_private[count.index].id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
}
