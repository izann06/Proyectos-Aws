# SSH
resource "aws_key_pair" "mi_llave_ssh" {
  key_name   = "${var.proyecto}-key"                 # Se define el nombre de la llave SSH
  public_key = file("~/.ssh/aws_ubuntu_key.pub") # Se especifica la llave publica esa ruta es donde esta mi llave
}

# Security Group
resource "aws_security_group" "mi_sg" {
  name        = "${var.proyecto}-sg"                         # Se define el nombre del grupo de seguridad
  description = "Permitir trafico SSH y HTTP al puerto 8080" # Se define la descripcion

  # Regla de entrada (Ingress) para SSH
  ingress {
    description = "SSH desde cualquier lugar"
    from_port   = 22            # Se define el puerto 22 para SSH
    to_port     = 22            # Se define el puerto 22 para SSH
    protocol    = "tcp"         # Se define el protocolo tcp porque SSH utiliza el protocolo tcp
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 significa "desde cualquier IP de internet"
  }

  # Regla de entrada (Ingress) para la API (Puerto 8080)
  ingress {
    description = "Trafico para la API FastAPI"
    from_port   = 8080          # Se define el puerto 8080 para la API FastAPI
    to_port     = 8080          # Se define el puerto 8080 para la API FastAPI
    protocol    = "tcp"         # Se define el protocolo tcp porque la API FastAPI utiliza el protocolo tcp
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 significa "desde cualquier IP de internet"
  }

  # Regla de salida (Egress): Permitir que el servidor salga a internet (necesario para descargar Docker)
  egress {
    from_port   = 0             # Se define el puerto 0 para permitir cualquier protocolo
    to_port     = 0             # Se define el puerto 0 para permitir cualquier protocolo
    protocol    = "-1"          # -1 significa "todos los protocolos"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 significa "desde cualquier IP de internet"
  }
}

# Buscar el S.O en AWS

# Buena práctica: Los IDs de Ubuntu cambian cada mes. 
# En vez de poner el ID a mano, le digo a Terraform que busque el más reciente.
data "aws_ami" "ubuntu_latest" {
  most_recent = true             # Esto le dice a Terraform que busque el AMI más reciente
  owners      = ["099720109477"] # El ID de Canonical (creadores de Ubuntu)
  filter {
    name   = "name"                                                      # Filtra los AMIs por nombre
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] # Se especifica el nombre del AMI
  }
}

# Instancia EC2 (El Servidor)

resource "aws_instance" "mi_servidor" {
  ami           = data.aws_ami.ubuntu_latest.id # Usa el sistema operativo que encontró arriba
  instance_type = "t2.micro"                    # La máquina gratuita de AWS
  # Conectamos las piezas que creamos antes
  key_name               = aws_key_pair.mi_llave_ssh.key_name
  vpc_security_group_ids = [aws_security_group.mi_sg.id]
  # Script de automatización que se ejecuta al encender la máquina
  user_data = <<-EOF
              #!/bin/bash
              # Actualizamos el sistema
              apt-get update -y
              # Instalamos Docker
              apt-get install -y docker.io
              # Encendemos Docker y hacemos que arranque con el sistema
              systemctl start docker
              systemctl enable docker
              # Damos permisos al usuario 'ubuntu' para usar Docker sin poner 'sudo'
              usermod -aG docker ubuntu
              EOF
  tags = {
    Name = "${var.proyecto}-server"
  }
}
