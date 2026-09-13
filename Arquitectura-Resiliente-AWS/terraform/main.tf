# LLamada al módulo de red (Networking)
module "network" {
  source = "./modules/network"

  # Le pasamos las variables desde el root al módulo
  nombre_proyecto        = var.nombre_proyecto
  vpc_cidr               = var.vpc_cidr
  subredes_publicas_cidr = var.subredes_publicas_cidr
  subredes_privadas_cidr = var.subredes_privadas_cidr
  
  # Usamos las zonas de disponibilidad a y b de la region actual
  zonas_disponibilidad   = ["${var.aws_region}a", "${var.aws_region}b"]
}
