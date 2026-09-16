# Redes (VPC y Subredes)

# Búsqueda de la VPC por defecto de la cuenta
data "aws_vpc" "default" {
  default = true
}

# Búsqueda de las subredes dentro de la VPC por defecto.
# Se requieren al menos dos para alta disponibilidad del Load Balancer.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
