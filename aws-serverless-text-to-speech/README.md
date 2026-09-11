🎙️ AWS Serverless Text-to-Speech: Mi Laboratorio Cloud

Bienvenido/a a este repositorio. Este proyecto es el resultado de mi inmersión práctica en el mundo del Cloud Computing y la Infraestructura como Código (IaC).

Aquí documento cómo he diseñado, desplegado y asegurado una arquitectura 100% Serverless en Amazon Web Services utilizando Terraform, con un objetivo claro: aprender haciendo, tropezando y solucionando problemas reales.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

🎯 El Objetivo

La premisa del proyecto es sencilla pero muy visual: automatizar la conversión de texto a audio sin tener que encender ni mantener servidores.

Quería construir un sistema que solo consumiera recursos (y por tanto, dinero) en el momento exacto en el que se le necesita. El flujo es el siguiente:

- Subes un archivo .txt a la nube.

- El sistema lo detecta y se "despierta" automáticamente.

- Una Inteligencia Artificial lee el texto y genera un archivo .mp3.

- El sistema guarda el audio y vuelve a dormirse.

Todo esto, construido de forma automatizada y replicable mediante código, manteniendo la factura de AWS estrictamente en 0,00€ aprovechando la capa gratuita.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

🛠️ Servicios y Tecnologías Aprendidas

Para lograr esto, he orquestado varios servicios de AWS, entendiendo no solo cómo funcionan de forma aislada, sino cómo se comunican entre sí de forma segura:

📦 Amazon S3 (Almacenamiento): Es el almacén del proyecto. He aprendido a estructurar buckets, separar los textos de los audios en carpetas y lo más importante, a usarlo como el trigger que dispara todo el proceso mediante notificaciones de eventos.

🧠 AWS Lambda (Cómputo): El cerebro de la operación. He programado la lógica en Python usando la librería boto3. He comprendido el paradigma Serverless, mi código solo se ejecuta cuando S3 le avisa a través de un evento.

🗣️ Amazon Polly (IA de Voz): El servicio de Machine Learning que se encarga de sintetizar el texto plano en voz natural (en este caso, usando la voz de Lucía).

🛡️ AWS IAM (Seguridad): Las reglas del sistema. He aprendido a aplicar el Principio de Menor Privilegio, creando Roles y Políticas de seguridad para asegurar que la Lambda solo pueda hacer estrictamente lo necesario.

🏗️ Terraform (Infraestructura como Código): Esta herramienta me ha permitido definir toda esta arquitectura en archivos de texto, gestionar dependencias (como la creación automática de archivos .zip) y desplegar o destruir la infraestructura completa en segundos.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

🚀 El Viaje: Paso a Paso

El desarrollo no fue simplemente escribir código y que funcione. Lo dividí en fases lógicas simulando un entorno de trabajo real:

Cimentación y Seguridad: Primero, definí en Terraform el bucket de S3 y la identidad (Rol) de la Lambda, dejándola completamente ciega por defecto por motivos de seguridad.

El Cerebro: Desarrollé el script en Python. En lugar de escribir rutas absolutas, configuré Terraform para que le pasara el nombre del bucket a la Lambda mediante Variables de Entorno, una práctica esencial para mantener el código limpio y seguro.

El Puente de Comunicación: Finalmente, configuré los Triggers. Le di permiso explícito a S3 para que pudiera llamar a la Lambda cada vez que detectara un archivo con extensión .txt.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

🧗‍♂️ Obstáculos y Aprendizajes (La Realidad del Desarrollo)

La mejor parte de este proyecto han sido los errores. Tropezar con ellos me ha obligado a buscar en la documentación, leer logs en CloudWatch y entender realmente cómo es AWS. Estos fueron mis tres mayores aprendizajes:

- El guardia de seguridad y el AccessDenied: Al probar el proyecto por primera vez, el texto se leía, pero el .mp3 no se guardaba. Revisando los logs en la Lmabda dentoro de CloudWatch descubrí que AWS había bloqueado a mi propia Lambda. Eso pasó porque le había dado permiso (IAM) para leer (s3:GetObject) pero olvidé darle permiso explícito para escribir (s3:PutObject). 

- La exigencia de la sintaxis JSON: Terraform usa su propio lenguaje (HCL), pero AWS exige que las políticas de seguridad se envíen en JSON estricto. Me enfrenté a un error de despliegue (MalformedPolicyDocument) simplemente por escribir version = "2012-10-17" con la "v" en minúscula en lugar de mayúscula.

- El control de versiones y el archivo de estado: Aprendí por las malas la importancia de configurar un buen .gitignore. Comprendí por qué jamás se deben subir archivos .zip compilados ni el archivo terraform.tfstate al repositorio, asegurando la limpieza y seguridad del código público. Sin embargo, también entendí la necesidad de sí subir el .terraform.lock.hcl para garantizar que las versiones de las herramientas sean idénticas en cualquier máquina.
