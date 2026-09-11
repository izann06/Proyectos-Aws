import json
import boto3 # Libreria de python que permite interactuar con servicios de AWS

# Inicializo los clientes de AWS fuera de la función principal.
# Esto hace que la Lambda sea más rápida si se ejecuta varias veces seguidas.

s3_client = boto3.client('s3') # Cliente que interactua con s3
polly_client = boto3.client('polly') # Cliente que interactua con polly

def lambda_handler(event, context):
    try:
        # PASO 1: Descubrir quién ha despertado a la Lambda
        # Cuando subes un archivo a S3, AWS envía un 'event' (un diccionario) con los datos.
        registro = event['Records'][0]
        nombre_bucket = registro['s3']['bucket']['name']
        nombre_archivo = registro['s3']['object']['key']
        
        print(f"Iniciando proceso para el archivo: {nombre_archivo} en el bucket: {nombre_bucket}")

        # PASO 2: Leer el texto del archivo
        respuesta_s3 = s3_client.get_object(Bucket=nombre_bucket, Key=nombre_archivo)
        # El archivo viene en crudo (bytes), hay que decodificarlo a texto normal
        texto_a_leer = respuesta_s3['Body'].read().decode('utf-8')
        
        print("Texto extraído correctamente. Llamando a la IA de voz...")

        # PASO 3: Enviar el texto a Amazon Polly
        respuesta_polly = polly_client.synthesize_speech(
            Text=texto_a_leer,
            OutputFormat='mp3',
            VoiceId='Lucia' # Voz estándar en español (puedes cambiarla por 'Enrique' o 'Conchita')
        )

        # PASO 4: Guardar el nuevo audio en el mismo bucket
        # Cambiamos la extensión de .txt a .mp3
        nombre_audio = nombre_archivo.replace('.txt', '.mp3')
        
        if "AudioStream" in respuesta_polly:
            s3_client.put_object(
                Bucket=nombre_bucket,
                Key=f"audios/{nombre_audio}", # Lo guardamos dentro de una carpeta llamada 'audios'
                Body=respuesta_polly['AudioStream'].read(),
                ContentType='audio/mpeg'
            )
            print(f"¡Éxito! Audio guardado como: audios/{nombre_audio}")

        return {
            'statusCode': 200,
            'body': json.dumps('Conversion de texto a voz completada')
        }

    except Exception as e:
        print(f"Error catastrofico procesando el archivo: {e}")
        raise e