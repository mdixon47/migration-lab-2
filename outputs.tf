output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "source_instance_id" {
  value = aws_instance.source.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "instance_security_group_id" {
  value = aws_security_group.instance_sg.id
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}
