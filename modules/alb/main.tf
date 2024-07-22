################################################################################
# create application load balancer
################################################################################
resource "aws_lb" "aws-application_load_balancer" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_alb[0]]
  //subnets                    = [var.public_subnets[0],var.public_subnets[1] ,var.public_subnets[2],var.public_subnets[3]]
  subnets                    = tolist(var.public_subnets)
  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb"
  })
}
################################################################################
# create target groups for ALB - Default and Other
################################################################################
resource "aws_lb_target_group" "alb_target_group_default" {
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-tg-default"
  })
}

resource "aws_lb_target_group" "alb_target_group_other" {
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/other/"
    timeout             = 5
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-tg-other"
  })
}

################################################################################
# create a listener on port 80 with redirect action - Default and Other
################################################################################
resource "aws_lb_listener" "alb_http_listener_default" {
  load_balancer_arn = aws_lb.aws-application_load_balancer.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_default.id

  }
}

################################################################################
# create a listener rule for other listener
################################################################################
resource "aws_lb_listener_rule" "alb_rule_other" {
  listener_arn = aws_lb_listener.alb_http_listener_default.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_other.arn
  }
  condition {
    path_pattern {
      values = ["/other/"]
    }
  }
}

################################################################################
# Target Group Attachment with Instance
################################################################################

resource "aws_alb_target_group_attachment" "alb_tg_attach_default" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.alb_target_group_default.arn
  target_id        = element(var.instance_ids, count.index)
}


resource "aws_alb_target_group_attachment" "alb_tg_attach_other" {
  count            = length(var.instance_ids_other)
  target_group_arn = aws_lb_target_group.alb_target_group_other.arn
  target_id        = element(var.instance_ids_other, count.index)
}
