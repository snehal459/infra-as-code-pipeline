########################################
# CLOUDWATCH LOG GROUP
########################################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/my-app"
}

########################################
# ECS CLUSTER
########################################
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

########################################
# IAM ROLE
########################################
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

########################################
# TASK DEFINITION
########################################
resource "aws_ecs_task_definition" "task" {
  family                   = "my-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.ecr_image
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/my-app"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

########################################
# ALB
########################################
resource "aws_lb" "alb" {
  name               = "my-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
}

########################################
# TARGET GROUP
########################################
resource "aws_lb_target_group" "tg" {
  name        = "my-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/health"
    port = "traffic-port"
  }
}

########################################
# LISTENER
########################################
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

########################################
# ECS SERVICE
########################################
resource "aws_ecs_service" "service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = 5000
  }

  depends_on = [
    aws_lb_listener.listener
  ]
}
########################################
# AUTO SCALING TARGET
########################################
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

########################################
# AUTO SCALING POLICY (CPU BASED)
########################################
resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0   # scale if CPU > 50%
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}