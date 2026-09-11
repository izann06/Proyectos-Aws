provider "aws" {
  region = "us-east-1" # Defino el proveedor de cloud (AWS) junto con la región donde se desplegarán los servicios (Norte de Virginia)
}

# Servicio S3
resource "aws_s3_bucket" "bucket_textos" {
  bucket        = "texto-a-audio-izan-2026" # Nombre del bucket s3
  force_destroy = true                      # Permite que el bucket sea eliminado incluso si contiene objetos (útil para desarrollo, pero peligroso en producción)
}

# Servicio de Rol con IAM
resource "aws_iam_role" "lambda_ejecucion" { # Rol que tiene permisos para ejecutar la función lambda
  name = "rol_ejecucion_lambda_text"         # Nombre del rol
  assume_role_policy = jsonencode({          # Política de confianza
    Version = "2012-10-17"                   # Version de la política de confianza
    Statement = [{                           #Declaracion
      Action = "sts:AssumeRole"              # Accion que se permite
      Effect = "Allow"                       # Efecto que se permite
      Principal = {
        Service = "lambda.amazonaws.com" # Servicio que tiene permisos para ejecutar la función lambda
      }
    }]
  })
}

# Compresión de la lambda en un archivo zip

data "archive_file" "codigo_lambda_zip" {
  type        = "zip"                                   # Tipo de archivo que se va a crear
  source_dir  = "${path.module}/../src"                 # ruta donde se encuentra la lambda de python
  output_path = "${path.module}/../lambda_function.zip" # ruta donde se guardara el archivo zip
}

# Servicio Lambda
resource "aws_lambda_function" "lambda_texto" {                              # Definición de la función lambda
  filename         = data.archive_file.codigo_lambda_zip.output_path         # Archivo zip de la lambda
  function_name    = "convertidor_texto_a_voz"                               # Nombre de la función lambda
  role             = aws_iam_role.lambda_ejecucion.arn                       # ARN del rol de IAM
  handler          = "lambda_function.lambda_handler"                        # nombre del archivo python . nombre de la funcion
  runtime          = "python3.12"                                            # version de python
  source_code_hash = data.archive_file.codigo_lambda_zip.output_base64sha256 # hash del archivo zip para detectar cambios

  #Variables de entorno (No hay que poner los valores fijos en el código de terraform si queremos tener seguridad, usamos variables de entorno)
  environment {
    variables = {
      BUCKET_NOMBRE = aws_s3_bucket.bucket_textos.bucket # Nombre del bucket s3
    }
  }
}

# Politica de permisos para la lambda
resource "aws_iam_policy" "lambda_permisos" {
  name        = "politica_permisos_lambda"
  description = "Permisos para que la lambda acceda a CloudWatch, S3 y Polly (IA)"

  #Se define la politica de permisos
  policy = jsonencode({
    Version = "2012-10-17"

    # Permisos Cloudwatch
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*" # Se permite todo lo relacionado con la creacion, escritura y lectura de logs
      },

      # Permisos S3
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", # Se permite la lectura de objetos del bucket
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.bucket_textos.arn}/*" # Se permite la lectura de objetos del bucket
      },
      # Permisos Polly
      {
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech" # Se permite la sintesis de voz
        ]
        Resource = "*" # Polly no requiere permisos de recursos, esto se lo da AWS por defecto
      }
    ]
  })
}

#Union del rol con la politica (attach)
resource "aws_iam_role_policy_attachment" "conexion_rol_politica" {
  role       = aws_iam_role.lambda_ejecucion.name
  policy_arn = aws_iam_policy.lambda_permisos.arn
}

# Permiso para que S3 pueda ejecutar la lambda (TRIGGER)
resource "aws_lambda_permission" "permitir_s3" {
  statement_id  = "permiso_s3_trigger"                           # Identificador unico para este permiso
  action        = "lambda:InvokeFunction"                        # Accion que se permite
  function_name = aws_lambda_function.lambda_texto.function_name # Nombre de la funcion lambda
  principal     = "s3.amazonaws.com"                             # Servicio que tiene permisos para ejecutar la función lambda
  source_arn    = aws_s3_bucket.bucket_textos.arn                # ARN del bucket s3
}

# Notificacion de bucket s3
resource "aws_s3_bucket_notification" "notificacion_bucket" {
  bucket = aws_s3_bucket.bucket_textos.id # Nombre del bucket s3

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_texto.arn
    events              = ["s3:ObjectCreated:*"] # Eventos que activan la lambda (subida de objetos)
    filter_suffix       = ".txt"                 # Filtra por extension de archivo
  }

  depends_on = [aws_lambda_permission.permitir_s3] # Dependencia para que la lambda se cree antes de la notificacion del bucket
}
