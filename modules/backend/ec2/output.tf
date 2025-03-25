output "backend_asg" {
  value = aws_autoscaling_group.backend_asg.name
}
output "be_alb_dns_name" {
  value = aws_lb.backend_alb.dns_name
}

output "be_alb_zone_id" {
  value = aws_lb.backend_alb.zone_id
}
