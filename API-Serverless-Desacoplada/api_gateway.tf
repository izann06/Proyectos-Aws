# 1. La API (La Centralita HTTP)
resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.project}-http-api"
  protocol_type = "HTTP"
}

# 2. El Entorno (Stage)
# Uso $default para que la API se despliegue automáticamente sin necesidad
# de gestionar versiones manualmente cada vez que haga un cambio.
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "$default"
  auto_deploy = true
}

# 3. La Integración (El Cable)
# Conecta físicamente el API Gateway con nuestra función Lambda.
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  # AWS_PROXY significa que le paso a la Lambda la petición HTTP entera (headers, body, etc.)
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda_function.invoke_arn #ARN de invocación de la función Lambda
  payload_format_version = "2.0"                                          # Versión moderna del formato de datos para Lambda
}

# 4. La Ruta (El Enrutador)
# Defino qué URL y qué método HTTP van a disparar mi Lambda.
resource "aws_apigatewayv2_route" "post_mensajes_route" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  # Cuando alguien haga un POST a midominio.com/mensajes, ejecuto la integración
  route_key = "POST /mensajes"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Permiso de Invocación (El Guardia de Seguridad de la Lambda)
# La Lambda por defecto rechaza cualquier llamada externa. Con esto le digo: 
# "Tranquila, autorizo a API Gateway a que te ejecute".
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # Para máxima seguridad, solo permitimos que ESTE API Gateway en concreto llame a la Lambda
  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*/*"
}
