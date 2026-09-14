# ==========================================
# Roles y Permisos (AWS IAM)
# ==========================================
# En AWS, por defecto nadie confía en nadie (seguridad Zero Trust).
# Como nuestro EC2 va a necesitar descargar la imagen desde el ECR,
# tenemos que crear un "Carnet de Identidad" (Rol) y dárselo al EC2.

# 1. El Rol base para la instancia EC2 (El Carnet en Blanco)
# En AWS, las máquinas nacen sin identidad. Aquí fabricamos un Carnet en blanco.
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.proyecto}-ecs-instance-role"

  # La "assume_role_policy" es la regla que dice: "¿Quién tiene derecho a ponerse 
  # este carnet colgado al cuello?". Al poner Service = "ec2.amazonaws.com", 
  # aseguramos que solo las máquinas EC2 pueden usar este carnet.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. La Política Oficial (Los Permisos del Carnet)
# Un carnet en blanco no abre puertas. Aquí le pegamos una "pegatina dorada" de Amazon.
# Esa política (AmazonEC2ContainerServiceforEC2Role) otorga al portador del carnet 
# el permiso oficial para descargar imágenes de ECR y hablar con el orquestador ECS.
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# 3. El Perfil de Instancia (La Funda de Plástico)
# Peculiaridad de AWS: A los servidores EC2 no les puedes dar el Carnet (Role) directamente en la mano.
# Te obliga a meter el Carnet dentro de una "funda de plástico" (Instance Profile).
# Al crear la máquina EC2 más adelante, le entregaremos esta funda con el carnet dentro.
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.proyecto}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}
