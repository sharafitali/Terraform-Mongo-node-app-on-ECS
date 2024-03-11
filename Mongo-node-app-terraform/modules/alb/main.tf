

# --- ALB --- #


resource "aws_lb" "main" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_id
  security_groups    = [var.aws_security_group_http_id]
}

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 8000
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}
