
# --- ECS Cluster --- #

resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"
}




# --- ECS Capacity Provider --- #

resource "aws_ecs_capacity_provider" "main" {
  name = "demo-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.aws_autoscaling_group_arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }
}








# --- Cloud Watch Logs --- #

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 14
}


#--------TASK defintion------------



resource "aws_ecs_task_definition" "app" {
  family             = "demo-app"
  task_role_arn      = var.ecs_task_role_arn
  execution_role_arn = var.ecs_exec_role_arn
  network_mode       = "awsvpc"
  cpu                = 1024
  memory             = 1024

  container_definitions = jsonencode([
    {
      name         = "mongodb",
      image        = "mongo:4.1",
      essential    = true,
      portMappings = [{ containerPort = 27017, hostPort = 27017 }],
      environment = [
        { name = "MONGO_INITDB_ROOT_USERNAME", value = "root" },
        { name = "MONGO_INITDB_ROOT_PASSWORD", value = "password" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = "us-east-1",
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-stream-prefix" = "mongodb"
        }
      }
    },
    {
      name         = "node_app",
      image        = "sharafit/ecs-node-blogy:latest",
      essential    = true,
      portMappings = [{ containerPort = 8000, hostPort = 8000 }],
      environment = [
        # { name = "MONGO_URL", value = "mongodb://sabi:sabi%40123@mongodb:27017/admin" }
        { name = "MONGO_URL", value = "mongodb://root:password@localhost:27017/admin"
 }
        
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-region"        = "us-east-1",
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-stream-prefix" = "node"
        }
      }
    }
  ])
}



# --- ECS Service ---#



resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2

  network_configuration {
    security_groups = [var.aws_security_group_ecs_task_id]
    subnets         = var.public_subnet_id
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  load_balancer {
    target_group_arn = var.aws_lb_target_group_arn
    container_name   = "node_app"
    container_port   = 8000
  }

  depends_on = [var.aws_lb_target_group_app]
}