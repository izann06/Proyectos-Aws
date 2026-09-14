variable "region" {
  description = "Región de AWS donde desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Nombre base para los recursos"
  type        = string
  default     = "fase2-ecs"
}
