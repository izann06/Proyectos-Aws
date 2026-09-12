output "ip_publica_del_servidor" {
  description = "Esta es la IP pública donde se puede acceder a nuestra API"
  value       = aws_instance.mi_servidor.public_ip
}

output "comando_ssh" {
  description = "Comando para conectarse al servidor"
  value       = "ssh -i ~/.ssh/aws_ubuntu_key ubuntu@${aws_instance.mi_servidor.public_ip}"
}
