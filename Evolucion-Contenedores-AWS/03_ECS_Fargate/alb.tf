# Application Load Balancer (ALB)

# 1. Balanceador de carga
resource "aws_lb" "api_alb" {
  name               = "${var.proyecto}-alb"
  internal           = false                     # Accesible desde Internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  # Requiere al menos 2 subredes por alta disponibilidad
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "ALB de Fargate"
  }
}

# 2. Target Group
# Destino de los contenedores Fargate
resource "aws_lb_target_group" "api_tg" {
  name        = "${var.proyecto}-tg"
  port        = 8080               # Puerto de la API
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"               # CRÍTICO PARA FARGATE: Las tareas en Fargate usan tipo "ip", no "instance".

  # Configuración del chequeo de salud (Health Check)
  health_check {
    path                = "/"      
    healthy_threshold   = 2        
    unhealthy_threshold = 2        
    timeout             = 5
    interval            = 30
    matcher             = "200"    
  }
}

# 3. Listener
# Escucha por el puerto 80 (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Redirección al Target Group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# 4. Output
# Imprime la URL del ALB al finalizar
output "alb_url" {
  description = "URL para acceder a la API"
  value       = "http://${aws_lb.api_alb.dns_name}"
}
