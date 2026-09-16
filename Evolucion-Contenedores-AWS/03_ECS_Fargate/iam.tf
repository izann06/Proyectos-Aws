# Roles y Permisos (AWS IAM)

# ECS Fargate necesita permiso explícito para descargar imágenes de ECR
# y escribir logs en CloudWatch.

# 1. Rol de ejecución
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.proyecto}-ecs-execution-role"

  # Política de confianza para el servicio ECS
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Adjuntar política oficial de AWS
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
