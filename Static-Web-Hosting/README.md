# 🌐 Frontend Serverless: Alojamiento Estático con S3 y CloudFront

Este proyecto demuestra cómo alojar una página web estática (HTML/CSS) de manera profesional en AWS, utilizando Infraestructura como Código (**Terraform**). 

Alojar una web en un servidor tradicional (EC2) encendido 24/7 resulta ineficiente para contenido estático. La solución de la industria es utilizar **Amazon S3** para el almacenamiento masivo y **Amazon CloudFront** como CDN (Content Delivery Network) para servir la web desde el borde (Edge), lo que reduce la latencia, mejora la seguridad y minimiza los costes casi a cero.

## 🏗️ Arquitectura del Proyecto

El flujo de una petición web sigue esta ruta:

`Usuario ➡️ Internet ➡️ CloudFront (CDN) ➡️ S3 (Almacenamiento)`

*(Nota: En una arquitectura completa de producción con un dominio propio, el flujo iniciaría en **Route 53** para la resolución DNS hacia CloudFront).*

### Componentes de AWS (Terraform):
1. **S3 Bucket (`s3.tf`)**:
   - Actúa como el disco duro de nuestra web.
   - **Seguridad**: Configurado como 100% privado. El acceso público directo está bloqueado a nivel de cuenta (`aws_s3_bucket_public_access_block`). Esto es importante ya que al estar público pueden encontrar el bucket incluso acceder a nuestro S3 y descargar los archivos que hay dentro y el problema es que todo lo que sale de AWS te lo cobran por lo que te arruinarias.  
   - Tiene una política de recursos (`aws_s3_bucket_policy`) que permite acceso de lectura **exclusivamente** a CloudFront.

2. **CloudFront (`cloudfront.tf`)**:
   - Funciona como un caché global. Cuando un usuario en España pide la web, CloudFront se la entrega desde un servidor en España (Edge location), sin tener que viajar hasta el S3 en Virginia (`us-east-1`).
   - **Origin Access Control (OAC)**: El estándar más moderno de AWS. CloudFront firma criptográficamente cada petición que hace al S3 usando **SigV4** para demostrar que está autorizado.
   - Forzamos redirección automática de HTTP a HTTPS.

## 🛠️ Cómo Desplegar

1. **Inicializar y aplicar Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   *(Importante: CloudFront puede tardar entre 5 y 10 minutos en crear la distribución global).*

2. **Subir los archivos de la web:**
   Una vez Terraform termine, escupirá dos *Outputs*: el nombre del bucket (`s3_bucket_name`) y la URL pública (`cloudfront_url`).
   Sube la carpeta `src/` al bucket S3 usando AWS CLI:
   ```bash
   aws s3 sync src/ s3://TU_BUCKET_NAME_AQUI
   ```

3. **Ver la web:**
   Abre la URL de CloudFront en tu navegador (ej: `https://d3xxxxxx.cloudfront.net`) y verás la landing page.

### 🔄 Cómo actualizar la web manualmente (Sin CI/CD)

Si haces un cambio en el código HTML/CSS y quieres que se refleje en producción, no basta con subirlo al S3, ya que CloudFront guarda en su memoria caché la versión antigua para ahorrar recursos. Sigue estos dos pasos:

1. **Subir los archivos modificados a S3:**
   ```bash
   aws s3 sync src/ s3://TU_BUCKET_NAME_AQUI
   ```
   *(También puedes hacerlo en la Consola de AWS en la sección de S3 y luego en bucket que creaste para subir los archivos, pero yo lo enseño usando terraform)*

2. **Invalidar la caché de CloudFront:**
   Tenemos que forzar a CloudFront a que olvide la versión antigua y vaya a buscar la nueva al S3. Ejecuta esto con el ID de tu distribución (lo puedes ver en la consola de AWS o usando `terraform state show aws_cloudfront_distribution.cdn`):
   ```bash
   aws cloudfront create-invalidation --distribution-id TU_DISTRIBUTION_ID_AQUI --paths "/*"
   ```
   *(El `/*` indica que borre de la caché absolutamente todos los archivos).*

## 🧹 Limpieza

Como siempre, para evitar costes residuales cuando termines de probar la arquitectura:
```bash
terraform destroy
```
