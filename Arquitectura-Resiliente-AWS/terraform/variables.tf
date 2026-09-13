variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "nombre_proyecto" {
  type    = string
  default = "app-resiliente-v1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subredes_publicas_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subredes_privadas_cidr" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24"]
}
