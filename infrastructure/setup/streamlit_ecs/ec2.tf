resource "aws_iam_role" "ec2_instance_role" {
  name               = "iam_role_ec2_ecs"
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "main" {
  name = "analytics_ecs"
  role = aws_iam_role.ec2_instance_role.id
}

resource "aws_launch_template" "main" {
  name_prefix   = "ecs-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  # key_name               = "ec2ecsglog"
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }
  user_data = base64encode(data.template_file.user_data.rendered)

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "main" {
  vpc_zone_identifier = [aws_subnet.subnet_us-east-1a.id, aws_subnet.subnet_us-east-1b.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_lb" "main" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = [aws_subnet.subnet_us-east-1a.id, aws_subnet.subnet_us-east-1b.id]
}

resource "aws_lb_target_group" "main" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/"
    port = 8501
  }

}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
