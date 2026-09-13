output "vpc_id" {
  description = "El ID de la VPC creada"
  value       = aws_vpc.principal.id
}

output "subredes_publicas_ids" {
  description = "Lista con los IDs de las subredes publicas"
  value       = aws_subnet.publicas[*].id
}

output "subredes_privadas_ids" {
  description = "Lista con los IDs de las subredes privadas"
  value       = aws_subnet.privadas[*].id
}
