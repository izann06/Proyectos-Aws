# Empaquetar la función Lambda en un archivo zip
data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/function.zip"
}

# Lambda function
resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_function_zip.output_path
  function_name = "${var.project}-lambda-function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  code_sha256   = data.archive_file.lambda_function_zip.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.tabla_ordenes.name
      SQS_QUEUE_URL  = aws_sqs_queue.cola_ordenes.url
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}
