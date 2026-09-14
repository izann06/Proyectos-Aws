# ==========================================
# Paso 1: AWS ECR (Elastic Container Registry)
# ==========================================
# ECR es el "Docker Hub" privado de Amazon.
# En lugar de compilar la imagen dentro del EC2, 
# la compilaremos fuera y la subiremos aquí.
# ECS se conectará a este registro para descargar la imagen.

resource "aws_ecr_repository" "mi_registro" {
  name = "${var.proyecto}-api-repo" # Nombre del repositorio en AWS

  # ==========================================
  # MUTABILITY (Mutabilidad de las etiquetas)
  # ==========================================
  # "MUTABLE" nos permite sobreescribir la etiqueta (tag) de una imagen. 
  # Por ejemplo, si subimos una imagen hoy etiquetada como 'latest' y mañana subimos
  # otra diferente también como 'latest', AWS borrará la antigua y guardará la nueva.
  # (En entornos de producción estricta se usa "IMMUTABLE" para obligar a usar tags únicos 
  # como v1.1, v1.2 y guardar un historial inalterable).
  image_tag_mutability = "MUTABLE"

  # ==========================================
  # IMAGE SCANNING (Escaneo de Seguridad)
  # ==========================================
  # Al poner 'scan_on_push = true', le decimos a ECR: "Cada vez que suba una imagen Docker, 
  # pásale tu antivirus gratis". AWS inspeccionará el interior de nuestro contenedor y 
  # nos avisará si el Python o el Linux que usamos tiene alguna vulnerabilidad de seguridad conocida.
  # Es una excelente práctica de DevSecOps.
  image_scanning_configuration {
    scan_on_push = true
  }

  # ==========================================
  # TAGS (Etiquetas de Metadatos)
  # ==========================================
  # Los 'tags' son "post-its" que pegamos a nuestro recurso en AWS. 
  # Sirven para organizarnos (saber quién lo creó o de qué proyecto es) y para 
  # facturación (poder pedirle a AWS: "Dime cuánto ha costado todo lo que tenga el tag Fase 2").
  tags = {
    Name = "Registro de Contenedores para la Fase 2"
  }
}
