import json   # Traduce texto de internet a diccionarios de Python
import os     # Permite leer las variables de entorno de la máquina
import boto3  # Librería oficial de AWS para conectarse a sus servicios
import uuid   # Genera identificadores únicos aleatorios

# 1. Inicialización de clientes
# Se definen fuera de la función principal para que AWS los mantenga en memoria 
# si la Lambda se ejecuta muchas veces seguidas (ahorra tiempo de conexión).
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# 2. Función principal (Handler)
# Es el punto de entrada que AWS ejecuta cuando alguien llama a la API.
def lambda_handler(event, context):
    try:
        # Extraigo los nombres exactos de los recursos que inyectó Terraform
        tabla_nombre = os.environ['DYNAMODB_TABLE']
        cola_url = os.environ['SQS_QUEUE_URL']
        
        # Leo el cuerpo (body) de la petición HTTP recibida.
        # 'event' contiene toda la información de la petición que entra por API Gateway.
        body = json.loads(event.get('body', '{}'))
        mensaje_usuario = body.get('mensaje', 'Mensaje vacío')
        
        # Genero un identificador único para guardar este registro sin sobreescribir otros
        registro_id = str(uuid.uuid4())
        
        # Escritura en base de datos
        # Selecciono la tabla e inserto una nueva fila (Item)
        tabla = dynamodb.Table(tabla_nombre)
        tabla.put_item(
            Item={
                'id': registro_id,
                'mensaje': mensaje_usuario
            }
        )
        
        # Envío de mensaje a la cola
        # Publico un evento en SQS para que otro sistema lo procese de fondo
        sqs.send_message(
            QueueUrl=cola_url,
            MessageBody=json.dumps({
                'id_procesar': registro_id,
                'instruccion': 'Procesar este mensaje'
            })
        )
        
        # Respuesta HTTP al cliente
        # Devuelvo un código 200 (Éxito) rápidamente al cliente.
        # Gracias a esto, el usuario no tiene que esperar a que el servidor haga 
        # trabajos pesados de fondo (arquitectura desacoplada).
        return {
            'statusCode': 200,
            'body': json.dumps({
                'estado': 'ÉXITO',
                'id_generado': registro_id,
                'nota': 'Mensaje guardado en BD y encolado en SQS correctamente.'
            })
        }
        
    except Exception as e:
        # Si algo falla (ej: faltan permisos en iam.tf), el error se imprime
        # y se enviará automáticamente a los logs de CloudWatch.
        print(f"Error procesando la petición: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Error interno del servidor'})
        }
