# ECR (Elastic Container Registry)
# Repositorio privado para guardar la imagen Docker

resource "aws_ecr_repository" "mi_repo" {
  name                 = "${var.proyecto}-api-repo"
  image_tag_mutability = "MUTABLE"

  # force_delete permite a Terraform borrar el ECR incluso si contiene imágenes.
  force_delete = true 

  # Escaneo de vulnerabilidades automático cada vez que se sube una imagen
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "Repositorio ECR"
  }
}
