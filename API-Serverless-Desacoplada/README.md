# API Serverless Desacoplada

Una API HTTP sin servidor construida con AWS. Aprende a comunicar servicios de forma asíncrona y a guardar datos sin necesidad de gestionar un solo servidor.

---

## ¿Qué problema resuelve esto?

Imagina que construyes el botón de "Comprar ahora" de una tienda online.

**La forma tradicional (sin esta arquitectura):**
El usuario hace clic, tu servidor guarda la orden, contacta con el banco, genera la factura PDF y envía el email de confirmación... todo a la vez. El usuario espera mirando una rueda girando durante 8 segundos. Si el banco falla a la mitad, el proceso entero revienta y el usuario ve un error.

**La forma desacoplada (lo que hemos montado aquí):**
El usuario hace clic, tu API recibe la petición, guarda la orden en la base de datos y deja una nota en una cola diciendo "procesa esto después". En 200 milisegundos el usuario ya ve "Pedido recibido". Por detrás, otro sistema lee esa cola tranquilamente y hace el cobro, el PDF y el email (esto no está hecho aquí). Si el banco está caído, la nota en la cola espera y lo reintenta en 5 minutos. El usuario nunca vio un error.

Eso es exactamente lo que hace esta arquitectura. Y lo hace sin que tengas que gestionar ningún servidor.

---

## Cómo está montado todo

```
Usuario → POST /mensajes
            ↓
       API Gateway       (recibe la petición HTTP del mundo exterior)
            ↓
         Lambda          (ejecuta el código Python con la lógica)
           ↙ ↘
     DynamoDB   SQS      (guarda el dato y deja la tarea en cola)
```

**El flujo paso a paso:**

1. Alguien hace una petición `POST` a la URL de tu API con un JSON.
2. **API Gateway** actúa como la puerta de entrada y despierta a tu función **Lambda**.
3. La **Lambda** (código Python) hace dos cosas en paralelo:
   - Guarda el mensaje en una tabla de **DynamoDB** con un ID único.
   - Envía un aviso a una cola de **SQS** para procesarlo después.
4. La API responde al cliente con un `200 ÉXITO` en menos de un segundo.

---

## Estructura de archivos

```
API-Serverless-Desacoplada/
│
├── provider.tf        → Configuración de AWS (región, credenciales)
├── variables.tf       → Variables reutilizables (nombre del proyecto, región)
├── outputs.tf         → Las URLs que Terraform te devuelve al hacer apply
│
├── api_gateway.tf     → La puerta de entrada HTTP al mundo exterior
├── lambda.tf          → La función que ejecuta el código Python
├── iam.tf             → Los permisos que necesita la Lambda para funcionar
├── dynamodb.tf        → La base de datos NoSQL donde se guardan los mensajes
├── sqs.tf             → La cola de mensajes para procesamiento asíncrono
│
└── src/
    └── lambda_function.py   → El código Python que ejecuta la lógica
```

---

## Explicación de cada archivo

### `provider.tf`
Le dice a Terraform con qué cuenta de AWS debe hablar y en qué región.

### `variables.tf`
Define variables globales para no repetir el mismo texto en todos los archivos. Por ejemplo, el nombre del proyecto (`api-serverless-desacoplada`) se usa como prefijo en todos los recursos para que sea fácil identificarlos en AWS.

### `api_gateway.tf`
Contiene 5 bloques:
- **La API**: El recurso base, el "edificio" que recibirá las peticiones HTTP.
- **El Stage**: El entorno de despliegue. Usamos `$default` para que AWS gestione los redespliegues automáticamente.
- **La Integración**: El cable que conecta la puerta de entrada (API Gateway) con la lógica (Lambda).
- **La Ruta**: La regla que dice "cuando alguien haga POST a `/mensajes`, activa la integración".
- **El Permiso de Invocación**: La Lambda es paranoica por defecto y rechaza llamadas externas. Este bloque le dice que confíe en API Gateway.

### `lambda.tf`
Primero empaqueta el archivo Python en un `.zip` (que es el formato que AWS entiende). Luego crea la función Lambda, apuntándole al zip, diciéndole cuál es la función Python a ejecutar e inyectándole las variables de entorno (el nombre de la tabla y la URL de la cola) para que el código Python las pueda leer.

### `iam.tf`
IAM es el sistema de permisos de AWS. Aquí definimos tres cosas:
- **El Rol**: La "identidad virtual" que usará la Lambda. Como una tarjeta de empleado.
- **La Política**: La lista de lo que está permitido hacer. En este caso: escribir logs (CloudWatch), guardar en DynamoDB y enviar mensajes a SQS.
- **La Asignación**: El pegamento que une el rol y la política.

Sin esto, la Lambda ejecutaría el código Python y fallaría al intentar guardar en DynamoDB porque AWS le bloquearía el acceso. Ya que AWS funciona con principio de mínimo privilegio o "zero trust", es decir, por defecto no se tiene acceso a nada.

### `dynamodb.tf`
Crea una tabla NoSQL en la que cada mensaje queda guardado con un ID único como clave principal. Uso el modo `PAY_PER_REQUEST` para pagar solo por lo que se use. También activo `point_in_time_recovery` para tener copias de seguridad continuas de los últimos 35 días.

### `sqs.tf`
Crea dos colas:
- **La cola principal**: Donde llegan los mensajes a procesar.
- **La Dead Letter Queue (DLQ)**: La cola de mensajes fallidos. Si un mensaje falla 4 veces (porque el código falló o el servicio estaba caído), en lugar de quedarse en bucle infinito consumiendo dinero, AWS lo mueve aquí para que lo puedas inspeccionar después.

### `src/lambda_function.py`
El código Python que se ejecuta. Lee las variables de entorno, extrae el mensaje del body de la petición HTTP, genera un ID único, lo guarda en DynamoDB y le manda un aviso a SQS. Todo en menos de un segundo.

---

## Decisiones de Arquitectura

A lo largo de este proyecto he tomado decisiones importantes de diseño. Aquí explico el porqué:

### 1. ¿Empaquetar la Lambda con Terraform o con GitHub Actions (CI/CD)?

En este proyecto he usado el bloque `data "archive_file"` en Terraform para crear el `.zip` de la función Lambda directamente. 

- **Por qué lo he hecho así:** Es la forma más rápida y sencilla para proyectos pequeños o pruebas de concepto. Al ejecutar `terraform apply`, él mismo comprime el código Python y lo sube. Todo queda centralizado en una sola herramienta.
- **La alternativa (GitHub Actions):** En proyectos grandes y empresariales, Terraform **solo** debe gestionar la infraestructura (la Lambda vacía), y un sistema de CI/CD (como GitHub Actions) se encarga de empaquetar el código Python y actualizar la Lambda usando la AWS CLI. 
- **¿Cuándo usar cada una?** Si tu código Python es muy largo, tiene dependencias externas (librerías que hay que instalar con `pip`) o trabajan varios programadores en él todos los días, separarlo en GitHub Actions es obligatorio. Si es un script sencillo de un solo archivo (como el nuestro), Terraform es suficiente.

### 2. SQS: ¿Cola Estándar vs Cola FIFO?

En AWS existen dos tipos de colas, y yo he elegido la **Estándar** para este proyecto.

- **Cola Estándar (La que uso):**
  - **Ventaja:** Rendimiento casi infinito. Puede procesar decenas de miles de mensajes por segundo.
  - **Desventaja (Trade-off):** No garantiza el orden exacto (el mensaje 2 podría procesarse antes que el 1) y ocasionalmente podría entregar un mensaje duplicado. 
  - **¿Por qué la uso?** En el 95% de los casos (como enviar un email, procesar una imagen, o guardar un log), el orden no importa o mi código puede lidiar con duplicados. Es más barata y rápida.

- **Cola FIFO (First-In-First-Out):**
  - **Ventaja:** Garantiza el orden estricto (el mensaje 1 SIEMPRE va antes que el 2) y asegura que no haya duplicados (Exactly-Once Processing).
  - **Desventaja:** Son mucho más lentas (tienen un límite estricto de mensajes por segundo) y más caras.
  - **¿Cuándo se usaría?** Si estás procesando transacciones bancarias (donde restar dinero de una cuenta debe ir estrictamente en orden y jamás duplicarse) o actualizando el inventario de un producto con stock crítico (solo queda 1 entrada para un concierto).

---

## Cómo desplegarlo

### Requisitos previos
- Tener la [AWS CLI](https://aws.amazon.com/cli/) configurada con tus credenciales.
- Tener [Terraform](https://developer.hashicorp.com/terraform/downloads) instalado.

### Pasos

```bash
# 1. Entrar en la carpeta del proyecto
cd API-Serverless-Desacoplada

# 2. Inicializar Terraform (descarga los plugins de AWS)
terraform init

# 3. Ver qué va a crear antes de hacerlo
terraform plan

# 4. Crear toda la infraestructura en AWS
terraform apply
```

Al terminar, Terraform te devolverá las URLs de tu API:

```text
url_api_gateway       = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com"
url_endpoint_mensajes = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/mensajes"
```

**¿Para qué sirve esta URL exactamente?**
Esa URL es tu **API Gateway**, la puerta de entrada blindada a tu sistema. 
Aunque no puedas abrirla directamente en un navegador web (porque los navegadores hacen peticiones de lectura `GET` y nosotros le ordenamos a la API que solo escuche peticiones de escritura `POST`), es **exactamente aquí a donde tienes que apuntar** todas tus herramientas (como Postman, un frontend web o los comandos de terminal de abajo) para inyectar datos en tu base de datos enviando un JSON.

---

## Cómo probarlo

### Desde la terminal (PowerShell en Windows)

```powershell
Invoke-RestMethod `
  -Uri "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/mensajes" `
  -Method POST `
  -Body '{"mensaje": "Hola, estoy probando mi arquitectura serverless"}' `
  -ContentType "application/json"
```

Si todo funciona, deberías ver esto:

```
estado : ÉXITO
id_generado : 14e3531a-53ec-48cd-bd32-a19f8ccba50e
nota   : Mensaje guardado en BD y encolado en SQS correctamente.
```

### Desde la terminal (Linux / Mac)

```bash
curl -X POST "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/mensajes" \
  -H "Content-Type: application/json" \
  -d '{"mensaje": "Hola desde curl"}'
```

---

## Cómo verificarlo en la consola de AWS

### Ver los datos en DynamoDB

1. Entra a [AWS Console](https://console.aws.amazon.com) y busca **DynamoDB**.
2. En el menú izquierdo, haz clic en **Tablas**.
3. Busca la tabla `api-serverless-desacoplada-tabla-ordenes` y haz clic en ella.
4. Haz clic en **Explorar elementos de la tabla**.
5. Verás tus mensajes listados con su ID y el texto que enviaste.

### Ver los mensajes en SQS

1. Busca **SQS** en la consola de AWS.
2. Haz clic en la cola `api-serverless-desacoplada-queue`.
3. Haz clic en el botón **Enviar y recibir mensajes**.
4. Haz scroll hasta abajo y haz clic en **Sondear mensajes**.
5. Verás los mensajes que están esperando en la cola.

### Ver los logs de la Lambda en CloudWatch

Aquí puedes ver cada `print()` que ejecuta tu función Python y detectar errores.

1. Busca **Lambda** en la consola de AWS.
2. Entra a api-serverless-desacoplada-lambda-function.
3. Haz clic en `Monitorear`.
4. Verás las `metricas` y `logs`.

---

## Cómo destruir la infraestructura

Para no generar costes cuando no estás usando el proyecto, elimina todos los recursos con:

```bash
terraform destroy
```

Terraform te pedirá confirmación antes de borrar nada.

---

## Servicios utilizados y por qué

| Servicio | Por qué se usa |
|---|---|
| **API Gateway** | Para exponer la Lambda al exterior vía HTTP sin gestionar ningún servidor web |
| **Lambda** | Para ejecutar código Python bajo demanda, pagando solo por cada ejecución |
| **DynamoDB** | Base de datos NoSQL ultra-rápida, perfecta para guardar mensajes con alta disponibilidad |
| **SQS** | Cola de mensajes que desacopla el "recibir" del "procesar", haciendo el sistema más resiliente |
| **IAM** | Gestión de permisos para que cada servicio solo pueda acceder a lo que necesita |
| **CloudWatch** | Logs automáticos de todo lo que ejecuta la Lambda |
| **Terraform** | Para definir y versionar toda la infraestructura como código |

---

## Roadmap y Futuras Mejoras

Esta arquitectura es una base sólida, pero está diseñada deliberadamente como un punto de partida. Aquí hay varias vías de mejora para convertirla en un proyecto mucho más completo:

### 1. Añadir un endpoint GET para leer los datos
**¿Por qué no funciona si pongo la URL de mi API en el navegador?**
Actualmente, si pegas la URL en Google Chrome, te dará error. Esto es porque los navegadores hacen peticiones de tipo `GET` por defecto, pero nosotros hemos configurado nuestro API Gateway estrictamente para aceptar peticiones `POST` (ingesta de datos). Además, nuestro código Python actual solo sabe escribir en DynamoDB (`put_item`).

**La mejora:** 
Crear una segunda ruta en Terraform (`GET /mensajes`) y modificar el código Python (o crear una Lambda nueva) para que haga un `scan()` o `query()` en DynamoDB y devuelva los mensajes al usuario en formato JSON para que se puedan leer desde el navegador.

### 2. Frontend con S3 y CloudFront
En lugar de interactuar con la API mediante la terminal (`curl` o PowerShell), lo ideal es crear una pequeña web básica con HTML, CSS y un poco de JavaScript (para hacer los `fetch` a la API de forma visual).
Esa web estática se alojaría de forma barata y global usando un **Bucket S3** distribuido mediante la CDN de **CloudFront** (como en el Proyecto 3), cerrando el círculo de una aplicación 100% Serverless (Frontend web + Backend API).

### 3. Implementar un "Worker" para procesar la cola SQS
Actualmente, nuestra cola SQS es un "callejón sin salida". Los mensajes entran y se quedan ahí almacenados hasta que expiran. 
Para completar la arquitectura desacoplada, el siguiente paso lógico es crear un **Consumidor** (generalmente otra función Lambda). Esta nueva pieza estaría escuchando la cola SQS constantemente. Cada vez que llega un mensaje, lo coge, hace el trabajo pesado simulado (ej: procesar un pago simulado o mandar un email) y, al terminar, borra automáticamente el mensaje de la cola.
