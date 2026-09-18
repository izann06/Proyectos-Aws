# 1. Rol de ejecución
# Este rol es la identidad virtual que nuestra función Lambda va a utilizar.
# En AWS, los servicios no tienen usuario ni contraseña, usan roles temporales,
# para evitar hackeos y porque es más seguro y comodo para el usuario.
resource "aws_iam_role" "lambda_execution_role" {
  # Nombre interno que le di al rol dentro de la cuenta de AWS
  name = "${var.project}-lambda-role"

  # assume_role_policy (Política de Confianza):
  # Es un filtro de seguridad que bloquea quién puede "ponerse" este rol.
  # El jsonencode convierte el diccionario a un texto JSON válido que AWS requiere.
  assume_role_policy = jsonencode({
    Version = "2012-10-17" # Versión fija de la API de IAM (siempre es esta fecha)
    Statement = [
      {
        Effect = "Allow"          # Permitimos la acción
        Action = "sts:AssumeRole" # Acción de seguridad para asumir (adoptar) una identidad
        Principal = {
          # Solo permito que el servicio interno AWS Lambda asuma este rol.
          # Si un humano u otro servicio intenta usarlo, AWS lo denegará.
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Política de permisos
# Aquí defino la lista exacta de recursos que la Lambda puede tocar.
# Funciona bajo el principio de "Privilegio Mínimo": lo que no esté aquí, está prohibido.
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project}-lambda-policy"
  description = "Permisos necesarios para la ejecucion de la funcion lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permisos para escribir logs en CloudWatch
        # Necesarios para poder ver los 'print()' de Python y detectar errores.
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",  # Permite crear la carpeta principal de logs
          "logs:CreateLogStream", # Permite crear el archivo de texto para los logs
          "logs:PutLogEvents"     # Permite escribir líneas de texto dentro del archivo
        ]
        # Va entre comillas porque es un texto literal (String). 
        # Como no he creado CloudWatch con Terraform, no puedo referenciarlo
        # de forma dinámica. Los asteriscos (*) significan "cualquier recurso de logs".
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Permiso para insertar datos en DynamoDB
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem" # La acción exacta de la API de AWS para guardar una fila
        ]

        # Aunque no haya escrito ".arn" en el archivo dynamodb.tf, cuando Terraform 
        # crea la tabla, automáticamente lee el ARN de AWS y lo inyecta aquí.
        # Así evitas tener que copiar y pegar IDs larguísimos a mano.
        Resource = aws_dynamodb_table.tabla_ordenes.arn
      },
      {
        # Permiso para enviar mensajes a la cola SQS
        Effect = "Allow"
        Action = [
          "sqs:SendMessage" # La acción de la API para publicar en la cola
        ]
        # Igual que arriba: Terraform va al bloque aws_sqs_queue llamado "cola_ordenes"
        # que tienes en sqs.tf, y le extrae su ARN automáticamente.
        Resource = aws_sqs_queue.cola_ordenes.arn
      }
    ]
  })
}

# 3. Asignación de la política al rol (Rol + policy = permisos)
# Vinculo los permisos definidos arriba con el rol de la Lambda.
# Literalmente es el pegamento que une el recurso 1 y el recurso 2.
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  # Coge el nombre del rol del bloque 1
  role = aws_iam_role.lambda_execution_role.name
  # Coge el ARN (identificador) de la política del bloque 2
  policy_arn = aws_iam_policy.lambda_policy.arn
}
