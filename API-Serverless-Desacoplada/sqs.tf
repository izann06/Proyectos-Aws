# 1. Cola de mensajes fallidos (Dead Letter Queue)
resource "aws_sqs_queue" "cola_ordenes_deadletter" {
  name = "${var.project}-queue-dlq"
}

# 2. Cola principal
resource "aws_sqs_queue" "cola_ordenes" {
  name                      = "${var.project}-queue"
  delay_seconds             = 90     # Tiempo en segundos que un mensaje permanece invisible después de ser enviado
  max_message_size          = 262144 # Tamaño máximo de un mensaje en bytes (256KB)
  message_retention_seconds = 86400  # Tiempo en segundos que un mensaje permanece en la cola (1 día)
  receive_wait_time_seconds = 10     # Long Polling: Espera 10s antes de volver a preguntar si la cola está vacía
  
  redrive_policy = jsonencode({
    # ARN (Amazon Resource Name) de la cola de fallos que hemos creado arriba
    deadLetterTargetArn = aws_sqs_queue.cola_ordenes_deadletter.arn
    maxReceiveCount     = 4          # Reintentos antes de mandar el mensaje a la DLQ
  })

  tags = {
    Environment = "production"
  }
}
