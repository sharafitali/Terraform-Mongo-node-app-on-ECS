output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "aws_lb_target_group_app" {
  value = aws_lb_target_group.app

}

output "alb_dns_name" {
  value = aws_lb.main.dns_name

}