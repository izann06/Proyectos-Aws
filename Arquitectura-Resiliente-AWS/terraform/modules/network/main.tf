# 1. Crear la VPC (Nuestra red privada gigante)
resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.nombre_proyecto}-vpc"
  }
}

# 2. Subredes Públicas (2 en distintas Zonas de Disponibilidad)
resource "aws_subnet" "publicas" {
  count                   = length(var.subredes_publicas_cidr)
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = var.subredes_publicas_cidr[count.index]
  availability_zone       = var.zonas_disponibilidad[count.index]
  map_public_ip_on_launch = true # Asigna IP pública automáticamente a lo que entre aquí

  tags = {
    Name = "${var.nombre_proyecto}-publica-${count.index + 1}"
  }
}

# 3. Subredes Privadas (2 en distintas Zonas de Disponibilidad)
resource "aws_subnet" "privadas" {
  count             = length(var.subredes_privadas_cidr)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = var.subredes_privadas_cidr[count.index]
  availability_zone = var.zonas_disponibilidad[count.index]

  tags = {
    Name = "${var.nombre_proyecto}-privada-${count.index + 1}"
  }
}

# 4. Internet Gateway (La puerta de la VPC hacia Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${var.nombre_proyecto}-igw"
  }
}

# 5. Elastic IP y NAT Gateway (Para que las privadas puedan salir a internet sin ser vistas)
resource "aws_eip" "nat_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.publicas[0].id # El NAT siempre vive en una subred pública

  tags = {
    Name = "${var.nombre_proyecto}-nat"
  }
}

# 6. Tablas de Enrutamiento (Las señales de tráfico)

# Tabla para las subredes públicas (Ruta hacia el Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.nombre_proyecto}-public-rt"
  }
}

# Asociar subredes públicas a su tabla
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.subredes_publicas_cidr)
  subnet_id      = aws_subnet.publicas[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Tabla para las subredes privadas (Ruta hacia el NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.nombre_proyecto}-private-rt"
  }
}

# Asociar subredes privadas a su tabla
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.subredes_privadas_cidr)
  subnet_id      = aws_subnet.privadas[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
