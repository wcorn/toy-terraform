output "backend_asg" {
  description = "BE auto scaling group"
  value = aws_autoscaling_group.backend_asg.name
}
output "be_alb_dns_name" {
  description = "BE ALB DNS 이름"
  value = aws_lb.backend_alb.dns_name
}

output "be_alb_zone_id" {
  description = "BE ALB Zone ID"
  value = aws_lb.backend_alb.zone_id
}
