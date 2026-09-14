# ==========================================
# Paso 3: Orquestador (ECS Cluster)
# ==========================================
# Un clúster en ECS no es más que una agrupación lógica. 
# Piensa en él como un "tablero de ajedrez" vacío.
# Más adelante, crearemos servidores EC2 (las casillas) y los uniremos a este tablero.
# Y luego, ECS colocará contenedores (las piezas de ajedrez) sobre las casillas.

resource "aws_ecs_cluster" "mi_cluster" {
  name = "${var.proyecto}-cluster" # El nombre de nuestro tablero de ajedrez

  # ==========================================
  # INSIGHTS (Monitorización avanzada)
  # ==========================================
  # Al activar Container Insights, AWS recopilará métricas súper detalladas 
  # sobre cuánta CPU, RAM y red están gastando nuestros contenedores. 
  # Nos cobrarán unos céntimos, pero en un entorno profesional es obligatorio 
  # activarlo para saber si hay un cuello de botella o si estamos gastando de más.
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "Tablero ECS para la Fase 2"
  }
}
