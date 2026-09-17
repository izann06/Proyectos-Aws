# 1. Origin Access Control (OAC)
# Este es el mecanismo moderno y seguro para que CloudFront acceda a S3. OAC es un control de acceso que permite a CloudFront acceder al bucket S3.
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.proyecto}-oac"
  description                       = "OAC para acceder al bucket S3 del frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # Siempre firmo las peticiones al bucket S3
  signing_protocol                  = "sigv4"  # Se usa sigv4 para firmar las peticiones al bucket S3, es el estandar de AWS para firmar peticiones
}

# 2. Distribución CloudFront (CDN)
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true         # Habilito la distribución de CloudFront
  is_ipv6_enabled     = true         # Habilito IPv6 para la distribución de CloudFront
  default_root_object = "index.html" # El archivo principal que cargará al entrar a la web

  # Origen: Apunto al bucket S3
  origin {
    domain_name              = aws_s3_bucket.web_bucket.bucket_regional_domain_name # Nombre del dominio del bucket S3, se obtiene automaticamente de terraform
    origin_id                = "S3Origin"                                           # ID del origen, se usa para identificar el origen dentro de cloudfront
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id          # ID del origen, se usa para identificar el origen dentro de cloudfront
  }

  # Comportamiento de la caché (Cómo se sirven los archivos al usuario)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"] # Get es para obtener archivos, Head es para obtener metadatos de archivos. Solo uso GET porque no tengo backend que me devuelva otra cosa.
    cached_methods   = ["GET", "HEAD"] # Son los metodos que se pueden cachear. En este caso, solo Get y Head
    target_origin_id = "S3Origin"      # Apunta al origen que definí arriba

    viewer_protocol_policy = "redirect-to-https" # Redirigir HTTP a HTTPS (Seguridad) esto sirve por si alguien intenta acceder por http

    # No guardo cookies porque no tengo backend que las necesite. 
    # Si tuviera un backend, guardaria las cookies que necesito para que el backend pueda autenticar al usuario. 
    # Y guardaria las cookies que el backend me devuelva para que el usuario pueda navegar por la web.
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # TTLs (Tiempo de Vida en caché)
    # La magia del CDN es guardar los archivos en la caché por este tiempo
    # Cuando expira, pide uno nuevo al servidor.
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Restricciones geográficas (Puedes bloquear o permitir el acceso a ciertos países)
  # En este caso no hay restricciones.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Certificado SSL por defecto de CloudFront (ya que no uso dominio propio)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "CloudFront CDN FrontEnd"
  }
}
