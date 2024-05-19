resource "aws_ecs_cluster" "main" {
  name = "analytics-ecs-cluster"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = "main"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.main.arn

    managed_scaling {
      maximum_scaling_step_size = 3
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 2
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ecs/${aws_ecs_cluster.main.name}"
  retention_in_days = 30
}
