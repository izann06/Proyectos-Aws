variable "region" {
  description = "Región de AWS donde se va a desplegar la infraestructura"
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo para los nombres de los recursos"
  default     = "frontend-basico"
}
