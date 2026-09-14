# 🧱 Fase 1: EC2 + Docker (Infraestructura como Servicio - IaaS)

Esta es la primera etapa de mi viaje de contenedores. Representa la forma más tradicional de correr contenedores en la nube.

## 🎯 ¿Qué he construido?
He utilizado **Terraform** para aprovisionar un servidor Ubuntu virtual (Amazon EC2) en la nube. A través de un bloque llamado `user_data`, le indiqué al servidor que, nada más encenderse, descargara e instalara el motor de Docker. Por lo tanto, cuando se encendió la máquina por primera vez, ya tenía Docker instalado y listo para usarse.

Para desplegar la aplicación, he usado un robot de automatización (**GitHub Actions**).

## 🛠️ El Flujo de Trabajo (CI/CD)
1. Escribo código en la carpeta `/api`.
2. Hago un `git push` a la rama principal.
3. GitHub Actions detecta el cambio, busca mi llave SSH secreta y entra a la máquina EC2 en remoto.
4. El robot descarga la última versión de mi código usando `git clone / git pull`.
5. Ejecuta `docker build` en la propia máquina de AWS para compilar la imagen.
6. Ejecuta `docker run` exponiendo el puerto 8080.

## 🔐 Configuración de Secretos en GitHub
Para que el robot de GitHub Actions pueda conectarse a la máquina EC2, he tenido que configurar dos "Secrets" en los ajustes del repositorio (`Settings > Secrets and variables > Actions`):

- `EC2_HOST`: Aquí pongo la **IP Pública** que me devuelve Terraform al terminar de crear la máquina.
- `EC2_SSH_KEY`: Aquí pego el contenido exacto de mi **llave privada** SSH. 
  - *Nota técnica:* La llave se suele encontrar en la carpeta `$HOME/.ssh/` de mi ordenador (por ejemplo `~/.ssh/aws_ubuntu_key`). Es vital copiar la llave privada (la que **no** tiene extensión `.pub`), y copiarla enterita, desde `-----BEGIN OPENSSH PRIVATE KEY-----` hasta `-----END OPENSSH PRIVATE KEY-----`, sin arrastrar espacios en blanco extra.

## 🚀 Cómo probar este proyecto desde cero
Si acabas de descargarte este repositorio y quieres probarlo, estos son los pasos que debes seguir:

1. Abre tu terminal en la carpeta `01_EC2_Docker`.
2. Ejecuta `terraform init` para inicializar el proyecto y descargar los plugins de AWS.
3. Ejecuta `terraform apply` y escribe `yes`. Esto creará el servidor EC2 de fábrica.
4. Copia la IP Pública que aparecerá en tu terminal al terminar.
5. Ve a tu repositorio en GitHub y actualiza el secreto `EC2_HOST` con esa nueva IP, y asegúrate de añadir también tu llave privada en el secreto `EC2_SSH_KEY`.
6. Asegúrate de que las GitHub Actions están habilitadas en tu repositorio Settings > pages > Build and Deployment y pon GitHub Actions.
7. Ve a la pestaña **Actions** en GitHub, busca el flujo "Despliegue de FastAPI a AWS" y lánzalo manualmente (Run workflow) o haz un pequeño `git push` para despertarlo.
7. Cuando termine, abre tu navegador en `http://TU_IP:8080` para ver la API desplegada.

## ⚖️ Conclusiones de la Fase 1

### 👍 Lo Bueno
- **Control Total:** Como ingeniero, tengo acceso completo al sistema operativo (Linux). Puedo entrar por SSH, instalar herramientas, ver los logs crudos y entender exactamente qué está pasando.
- **Simplicidad inicial:** Es muy intuitivo porque es como si trabajara en mi propio ordenador portátil, pero en la nube.

### 👎 Lo Malo
- **Peligro del "Single Point of Failure":** Si mi única máquina EC2 se cuelga, se queda sin memoria o se apaga, la API se cae por completo y nadie la levantará automáticamente.
- **Mantenimiento pesado:** Soy responsable de actualizar el sistema operativo Ubuntu, parchear vulnerabilidades de seguridad y monitorizar el disco duro.
- **Lentitud:** El `docker build` se hace en el propio servidor de producción, gastando CPU valiosa y haciendo que cada despliegue sea más lento.

*(Para solucionar todos estos inconvenientes, he pasado a la Fase 2).*
