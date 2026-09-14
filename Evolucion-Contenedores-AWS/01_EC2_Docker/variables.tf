# Variables de configuración para el proyecto

# Region de AWS donde se desplegarán los recursos
variable "aws_region" {
  description = "Región de AWS en el Norte de Virginia"
  type        = string      # El tipo de variable es un string.
  default     = "us-east-1" # Esta es la región que utilizará Terraform para desplegar los recursos. Por defecto se establece us-east-1 por si no pasó ningún valor
}

# Nombre del proyecto para etiquetar los recursos
variable "proyecto" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
  default     = "api-fastapi-docker" # Este valor se utilizará para etiquetar los recursos desplegados por Terraform. Esto ayuda a identificar los recursos asociados al proyecto
}
