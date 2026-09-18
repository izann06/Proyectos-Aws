resource "aws_dynamodb_table" "tabla_ordenes" {
  name         = "${var.project}-tabla-ordenes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Configuración de copias de seguridad continuas (Point-in-time recovery)
  # Esto te permite restaurar la tabla a cualquier segundo en los últimos 35 días.
  point_in_time_recovery {
    enabled = true
  }
}
