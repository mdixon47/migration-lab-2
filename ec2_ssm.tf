# IAM role for SSM Session Manager
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-ssm-role"
    Host = "source-server"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-ssm-profile"
    Host = "source-server"
  })
}

# Amazon Linux 2023 AMI
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "source" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  user_data_base64 = base64encode(file("${path.module}/user_data.sh"))

  tags = merge(local.common_tags, {
    Name = "${var.project_prefix}-source"
    Host = "source-server"
  })
}

# Attach source server to ALB target group
resource "aws_lb_target_group_attachment" "source_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.source.id
  port             = 80
}
