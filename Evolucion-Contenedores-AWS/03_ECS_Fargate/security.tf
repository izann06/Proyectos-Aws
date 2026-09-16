# Seguridad (Grupos de Seguridad)

# 1. Security Group del Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.proyecto}-alb-sg"
  description = "Permitir trafico HTTP desde Internet al ALB"
  vpc_id      = data.aws_vpc.default.id

  # Regla de entrada: Permitir tráfico HTTP (80) global
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de salida: Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group de Fargate
# Restringe el acceso para permitir tráfico SOLO desde el ALB
resource "aws_security_group" "fargate_sg" {
  name        = "${var.proyecto}-fargate-sg"
  description = "Permitir trafico al contenedor SOLO desde el ALB"
  vpc_id      = data.aws_vpc.default.id

  # Regla de entrada: Solo puerto 8080 desde el Security Group del ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Regla de salida: Permitir salida a Internet para descargar actualizaciones
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
