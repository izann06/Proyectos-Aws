# La Receta y El Vigilante (Task & Service)

# 1. Task Definition (La Receta del Contenedor)
# Es un documento que le dice a Amazon exactamente CÓMO arrancar nuestro contenedor.
# Le decimos qué imagen usar, cuánta memoria darle y qué puertos abrir.

resource "aws_ecs_task_definition" "api_task" {
  family                   = "${var.proyecto}-api" # Nombre de esta receta
  requires_compatibilities = ["EC2"]               # Le decimos que esta receta es para ejecutarse en máquinas EC2
  network_mode             = "bridge"              # "bridge" es el modo de red clásico de Docker

  # Aquí definimos el contenedor (o contenedores) que forman esta tarea (en formato JSON)
  container_definitions = jsonencode([
    {
      name      = "api-container"                                           # Nombre que le damos al contenedor
      image     = "${aws_ecr_repository.mi_registro.repository_url}:latest" # Busca la imagen "latest" en nuestro almacén ECR
      cpu       = 256                                                       # Le damos 1/4 de vCPU (256 unidades de 1024)
      memory    = 256                                                       # Le damos 256 Megabytes de RAM
      essential = true                                                      # Si este contenedor falla, ECS lo considera un error crítico y reiniciará todo

      # Mapeo de puertos (Es idéntico a hacer 'docker run -p 8080:8080')
      portMappings = [
        {
          containerPort = 8080 # El puerto que usa nuestro código FastAPI (dentro de la caja)
          hostPort      = 8080 # El puerto que abrimos en la máquina EC2 (fuera de la caja)
          protocol      = "tcp"
        }
      ]

      # (Opcional pero vital) Enviar los logs del contenedor (los print de Python) a AWS CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.proyecto}-api"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true" # Crea la carpeta de logs automáticamente si no existe
        }
      }
    }
  ])
}

# 2. ECS Service (El Vigilante)
# Su trabajo es coger la receta (Task Definition) y asegurarse de que siempre haya
# un número exacto de copias vivas corriendo en el tablero de ajedrez (Cluster).
resource "aws_ecs_service" "api_service" {
  name            = "${var.proyecto}-service"            # Nombre de nuestro vigilante
  cluster         = aws_ecs_cluster.mi_cluster.id        # Le decimos qué tablero de ajedrez vigilar
  task_definition = aws_ecs_task_definition.api_task.arn # Le damos la receta que tiene que "cocinar"
  desired_count   = 1                                    # Le ordenamos: "Asegúrate de que haya 1 copia viva SIEMPRE"
  launch_type     = "EC2"                                # Le decimos que tire los contenedores en las máquinas EC2 esclavas

  # Configuraciones para actualizaciones sin cortes (Rolling Update)
  # Cuando subamos código nuevo, permite arrancar 1 contenedor nuevo (200%) 
  # ANTES de borrar el contenedor viejo, para que la web nunca se caiga.
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
}
