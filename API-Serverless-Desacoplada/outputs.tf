# URL de la API Gateway
output "url_api_gateway" {
  description = "URL de la API Gateway"
  # Extrae la URL base del despliegue automático ($default)
  value = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/${aws_apigatewayv2_stage.api_stage.name}"
}

# URL del endpoint de mensajes
output "url_endpoint_mensajes" {
  description = "URL completa para enviar mensajes (POST)"
  # Combina la URL base con la ruta que definimos en route_key (POST /mensajes)
  value = "${aws_apigatewayv2_api.api_gateway.api_endpoint}/${aws_apigatewayv2_stage.api_stage.name}/mensajes"
}
