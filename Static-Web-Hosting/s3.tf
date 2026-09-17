# 1. Crear el bucket S3 para alojar los archivos de la web
resource "aws_s3_bucket" "web_bucket" {
  bucket        = "${var.proyecto}-web-bucket-izan-001"
  force_destroy = true # Permite borrar el bucket aunque tenga archivos

  tags = {
    Name = "Bucket de FrontEnd S3"
  }
}

# 2. Bloquear el acceso público directo al bucket (Seguridad)
# Solo dejo que CloudFront lea el bucket, nadie más desde internet.
resource "aws_s3_bucket_public_access_block" "bloqueo_publico" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Política del bucket para permitir acceso SOLO a CloudFront (OAC)
resource "aws_s3_bucket_policy" "politica_cloudfront" {
  bucket = aws_s3_bucket.web_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.web_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}
