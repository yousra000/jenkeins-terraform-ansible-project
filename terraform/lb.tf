resource "aws_lb" "lb" {
  name     = "jenkins-lb"
  internal = false
  subnets = [
    for subnet in var.subnets :
    aws_subnet.subnets[subnet.name].id
    if subnet.type == "public"
  ]

  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public_sg.id]
  enable_deletion_protection = false

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn 
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }

  }

output "lb_url" {
  value = "http://${aws_lb.lb.dns_name}"
}


resource "aws_lb_target_group" "node" {
  name        = "node-tg"
  port        = 80 # Port your instances listen on (e.g., HTTP)
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id # Replace with your VPC ID if needed
  target_type = "instance"      # Direct traffic to EC2 instances

  health_check {
    path                = "/db" # Health check endpoint
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }
}