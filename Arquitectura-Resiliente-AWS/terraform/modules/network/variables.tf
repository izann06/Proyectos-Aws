variable "nombre_proyecto" {
  description = "Nombre del proyecto para las etiquetas"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC (El tamano de nuestra red)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subredes_publicas_cidr" {
  description = "Lista de CIDRs para las subredes publicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subredes_privadas_cidr" {
  description = "Lista de CIDRs para las subredes privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "zonas_disponibilidad" {
  description = "Zonas de disponibilidad a usar (Multi-AZ)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
