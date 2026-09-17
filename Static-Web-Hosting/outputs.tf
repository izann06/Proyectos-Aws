output "cloudfront_url" {
  description = "URL publica de la web (Generada por CloudFront)"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para subir los archivos de la web"
  value       = aws_s3_bucket.web_bucket.bucket
}
