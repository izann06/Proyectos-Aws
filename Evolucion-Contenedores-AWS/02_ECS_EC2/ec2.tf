# En el proyecto 1 creé una máquina suelta. Aquí creo un Auto Scaling Group
# para tener escalabilidad automática es decir, si una máquina se cae, se crea otra igual.

# 1. Grupo de Seguridad (El portero de discoteca)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.proyecto}-sg"                   # Nombre del grupo de seguridad
  description = "Permitir trafico HTTP al puerto 8080" # Descripción para saber para qué sirve

  # Regla de entrada (Ingress) para la API
  ingress {
    from_port   = 8080          # Abrimos el puerto 8080 (donde escucha nuestro FastAPI)
    to_port     = 8080          # Hasta el puerto 8080
    protocol    = "tcp"         # Usamos el protocolo TCP (el estándar web)
    cidr_blocks = ["0.0.0.0/0"] # Permitimos que CUALQUIER persona en internet pueda entrar
  }

  # Regla de entrada (Ingress) para SSH (Opcional, por si queremos investigar)
  ingress {
    from_port   = 22 # Abrimos el puerto 22 (el puerto oficial de SSH)
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitimos conexión SSH desde cualquier sitio
  }

  # Regla de salida (Egress)
  egress {
    from_port   = 0             # 0 significa "todos los puertos"
    to_port     = 0             # 0 significa "todos los puertos"
    protocol    = "-1"          # "-1" significa "todos los protocolos"
    cidr_blocks = ["0.0.0.0/0"] # Permitimos que el servidor salga a internet a descargar cosas (ej: imágenes Docker)
  }
}

# 2. Llave SSH (Para conectarnos al servidor)
resource "aws_key_pair" "ecs_key" {
  key_name   = "${var.proyecto}-key"             # Le damos un nombre a la llave en AWS
  public_key = file("~/.ssh/aws_ubuntu_key.pub") # Subimos la llave pública que ya tienes en tu ordenador
}

# 3. Buscar la Imagen del Sistema Operativo (AMI)

# Ya no usamos un Ubuntu básico. Usamos "Amazon Linux 2023 ECS Optimized".
# Esta es una versión especial de Linux fabricada por Amazon que YA trae Docker instalado
# y trae un programa llamado "Agente ECS" que sabe cómo hablar con nuestro Clúster.
data "aws_ssm_parameter" "ecs_ami" {
  # Esta ruta larguísima es simplemente un acceso directo de Amazon que siempre 
  # apunta a la última versión segura y actualizada de ese sistema operativo.
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# 4. La Plantilla de Lanzamiento (Launch Template)
# Es el molde de la máquina. Define las especificaciones de la máquina.
resource "aws_launch_template" "ecs_template" {
  name          = "${var.proyecto}-template"           # Nombre del molde
  image_id      = data.aws_ssm_parameter.ecs_ami.value # Usamos el Linux de ECS que buscamos arriba
  instance_type = "t2.micro"                           # Usamos la máquina gratuita de AWS
  key_name      = aws_key_pair.ecs_key.key_name        # Le inyectamos tu llave SSH

  # Aquí está el permiso de la máquina (IAM, el CARNET con la funda)
  # Le decimos que cuando cree la máquina, le entregue la funda de plástico con los permisos.
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Configuración de red de la máquina
  network_interfaces {
    associate_public_ip_address = true                           # Queremos que tenga una IP Pública para poder ver la web
    security_groups             = [aws_security_group.ecs_sg.id] # Le asignamos el portero de discoteca que creamos arriba
  }

  # Le asigno un nombre a todas las máquinas que se fabriquen con este molde
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.proyecto}-instancia"
    }
  }

  # ¡LA LÍNEA MÁGICA DE CONFIGURACIÓN! (user_data)
  # Este es el script que se ejecuta automáticamente la primera vez que se enciende la máquina.
  # Lo único que hace es escribir el nombre de nuestro Clúster (fase2-ecs-cluster) en un archivo interno.
  # Así, el Agente ECS de la máquina sabe exactamente a qué "tablero de ajedrez" tiene que unirse.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.mi_cluster.name}" >> /etc/ecs/ecs.config
              EOF
  )
}

# 5. El Auto Scaling Group (La Fábrica)
# Este bloque es el encargado de encender y apagar máquinas usando el molde (Template) de arriba.
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.proyecto}-asg"        # Nombre de la fábrica
  vpc_zone_identifier = data.aws_subnets.default.ids # Dónde debe colocar las máquinas (en tu red por defecto de AWS)
  desired_capacity    = 1                            # Queremos exactamente 1 máquina viva ahora mismo
  min_size            = 1                            # Si cae por debajo de 1, fabricará otra
  max_size            = 2                            # Límite máximo de máquinas que puede fabricar si hay mucho tráfico

  # Le decimos qué molde tiene que usar para fabricar las máquinas
  launch_template {
    id      = aws_launch_template.ecs_template.id # El ID del molde que creamos arriba
    version = "$Latest"                           # Usar siempre la última versión de ese molde
  }
}

# 6. Datos Auxiliares (VPC y Redes)

# Estos bloques solo sirven para que Terraform busque automáticamente cuál es la red (VPC) 
# por defecto de tu cuenta de AWS, sin que tú tengas que buscar el ID a mano.
data "aws_vpc" "default" {
  default = true # Busca la red por defecto
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] # Busca las subredes dentro de esa red por defecto
  }
}
