# Variables

variable "region" {
  description = "Región de AWS donde se va a desplegar la infraestructura"
  default     = "eu-west-1" # Irlanda
}

variable "proyecto" {
  description = "Nombre del proyecto (se usará como prefijo para los recursos)"
  default     = "fase3"
}
