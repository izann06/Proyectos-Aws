# Orquestador (ECS Cluster) y Tareas (Fargate)

# 1. Cluster ECS
resource "aws_ecs_cluster" "mi_cluster" {
  name = "${var.proyecto}-fargate-cluster"
}

# 2. Task Definition
# Requiere compatibilidad con FARGATE y network_mode "awsvpc".
resource "aws_ecs_task_definition" "api_task" {
  family                   = "${var.proyecto}-api-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256      # 0.25 vCPU
  memory                   = 512      # 512 MB de RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # Definición del contenedor en JSON
  container_definitions = jsonencode([
    {
      name      = "api-contenedor"
      image     = "${aws_ecr_repository.mi_repo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# 3. ECS Service
# Mantiene las tareas ejecutándose y conectadas al Load Balancer.
resource "aws_ecs_service" "api_service" {
  name            = "${var.proyecto}-api-service"
  cluster         = aws_ecs_cluster.mi_cluster.id
  task_definition = aws_ecs_task_definition.api_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Configuración de red del servicio (Exclusivo de awsvpc/Fargate)
  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = true # Necesario para descargar imágenes de ECR sin un NAT Gateway
  }

  # Conexión con el Load Balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.api_tg.arn
    container_name   = "api-contenedor"
    container_port   = 8080
  }

  # Ignorar los cambios en la task_definition gestionados por GitHub Actions.
  lifecycle {
    ignore_changes = [task_definition]
  }

  # Asegura que el Target Group esté listo antes de crear el servicio
  depends_on = [aws_lb_listener.http]
}
