resource "aws_ecs_service" "main" {
  name            = "analytics-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.ecs_task_desired_count

  network_configuration {
    subnets         = [aws_subnet.subnet_us-east-1a.id, aws_subnet.subnet_us-east-1b.id]
    security_groups = [aws_security_group.main.id]
  }

  placement_constraints {
    type = "distinctInstance"
  }

  triggers = {
    redeployment = plantimestamp()
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "analytics"
    container_port   = 8501
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  force_new_deployment = true
  depends_on           = [aws_autoscaling_group.main]
}
