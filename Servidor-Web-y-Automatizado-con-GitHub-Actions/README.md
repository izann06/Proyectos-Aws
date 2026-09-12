# Proyecto DevOps: Servidor Web Automatizado

Este documento refleja el paso a paso de mi aprendizaje práctico sobre DevOps, AWS, Docker, Terraform y GitHub Actions. Aquí documento la lógica detrás de cada archivo, los errores que he ido encontrando y sus soluciones.

---

## Paso 1: Construcción de la API con Python (FastAPI)

Elegimos **FastAPI** por ser un estándar moderno en la nube, ser muy rápido y generar documentación automática.

Un proyecto Python profesional necesita como mínimo dos cosas: las dependencias y el código.

### 1. Las Dependencias (`requirements.txt`)

Es el archivo donde se ponen todas las dependencias para que el gestor de paquetes de Python (`pip`) sepa qué descargar desde **PyPI** (el repositorio oficial de librerías de Python).

```text
fastapi==0.110.0
uvicorn==0.28.0
```

**Preguntas resueltas:**
- **¿Qué significa `>=` vs `==`?**
  - `>=` instala la versión indicada *o cualquier versión superior*. Es peligroso en producción porque si sale una versión nueva que rompe cosas, tu servidor dejará de funcionar sin que tú hayas tocado el código.
  - `==` fija la versión exacta (pinning). Es la mejor práctica en DevOps para garantizar la **reproducibilidad**.

### 2. El Código (`main.py`)

Aquí levantamos el servidor web.

**Preguntas resueltas:**
- **¿Qué hace el símbolo `@`?**
  - Se llama **Decorador**. Le da superpoderes a la función que tiene debajo. Por ejemplo, `@appIzan.get("/")` le dice al servidor que cuando alguien entre a la ruta raíz usando HTTP GET, debe ejecutar la función de abajo.
- **¿Por qué `fastapi` y `FastAPI` se escriben distinto en `from fastapi import FastAPI`?**
  - `fastapi` (minúsculas) es el **paquete/módulo** descargado. Por convención, van en minúsculas.
  - `FastAPI` (PascalCase) es la **Clase** (el molde). Por convención, las clases empiezan por mayúscula.
- **¿Para qué sirven el `title` y `description` si no los devuelvo en ninguna ruta?**
  - FastAPI autogenera una página web de documentación interactiva (Swagger UI). Si entras a `http://localhost/docs`, verás esa información y botones para probar tu API sin necesidad de herramientas externas.
- **¿Por qué un endpoint `/health`?**
  - Es fundamental en DevOps. Herramientas como AWS, Docker o Kubernetes hacen peticiones constantes a `/health` para saber si la aplicación sigue viva o si ha fallado y necesitan reiniciarla.

---

## Paso 2: Contenedorización con Docker

Docker nos permite meter la aplicación con su sistema operativo, Python y dependencias en una caja aislada ("contenedor"). Así evitamos el clásico problema de *"en mi máquina funciona, pero en el servidor no"*.

### Explicación del `Dockerfile` (Receta paso a paso)

1. `FROM python:3.11-slim`: Usamos una versión ligera (`slim`) de Linux con Python 3.11 para que el contenedor ocupe poco espacio y se descargue rápido.
2. `WORKDIR /app`: Creamos una carpeta `/app` dentro del contenedor para trabajar ahí, separando nuestra app de los archivos del sistema operativo.
3. **El truco de la Caché (Pregunta de entrevista):**
   ```dockerfile
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY . .
   ```
   Copiamos *primero* el `requirements.txt` y lo instalamos, antes de copiar el código fuente. ¿Por qué? Porque Docker guarda las capas en caché. Si cambiamos algo en `main.py`, Docker reutiliza la capa de dependencias (que tarda mucho en instalarse) y solo vuelve a procesar la copia del código.
4. `CMD ["uvicorn", "main:appIzan", "--host", "0.0.0.0", "--port", "8080"]`: El comando de arranque.
   - `main`: es el archivo `main.py`.
   - `appIzan`: es el nombre de la variable de la app.
   - `0.0.0.0`: Permite que la app acepte conexiones desde fuera del contenedor (no solo internas).

### Error documentado: "port is already allocated"

**El Error:**
Al hacer `docker run -d -p 8000:8000 --name ServidorAws servidoraws`, Docker dio error de red diciendo que el puerto estaba asignado.

**La Causa:**
El argumento `-p HOST:CONTENEDOR` mapea un puerto de tu máquina (Windows) a un puerto dentro del contenedor Docker. Si el puerto del Host (el de la izquierda) ya está siendo usado por otra aplicación u otro contenedor en tu ordenador, Docker no puede "secuestrarlo". Además, el contenedor se queda a medias en estado "Creado", bloqueando ese nombre.

**La Solución:**
1. Eliminar el contenedor que se quedó a medias: `docker rm ServidorAws`
2. Mapearlo a un puerto libre en el Host (por ejemplo, el 8080): `docker run -d -p 8080:8000 --name ServidorAws servidoraws`.
*(Nota: Si dentro del contenedor la app escucha en el 8080 por el CMD, el mapeo debe ajustarse a `-p PUERTO_HOST:8080`).*

---

## Paso 3: Preparando el terreno para AWS y Terraform

Antes de escribir Infraestructura como Código, tuve que preparar la seguridad:

### 1. Usuario IAM vs Usuario Raíz
**Lección aprendida:** NUNCA debo usar las Access Keys del usuario raíz (Root). Si se filtran, pueden borrarme la cuenta o generarme miles de euros en facturas.
- **Solución:** Fui a IAM en AWS, creé un usuario específico (`izan-admin`) con permisos de `AdministratorAccess`, generé sus propias Access Keys y las configuré en mi terminal ejecutando `aws configure`.

### 2. Llaves SSH modernas
Para conectarme al futuro servidor EC2 de forma segura sin usar contraseñas hackeables, generé una llave SSH usando el algoritmo más moderno y seguro:
`ssh-keygen -t ed25519 -f $HOME/.ssh/aws_ubuntu_key -N '""'`
- **¿Por qué sin contraseña (`-N '""'`)?** Porque más adelante, un robot (GitHub Actions) tendrá que usar esta llave. Si le pongo contraseña, el robot se quedará atascado esperando a que la teclee.

---

## Paso 4: Iniciando con Terraform (HCL)

Terraform es la herramienta que usaremos para crear toda la arquitectura en AWS con código. Su lenguaje (HCL) funciona por bloques.

**Buena práctica: Modularización**
En lugar de meter todo en un solo archivo, dividí la configuración base en dos:
1. `provider.tf`: Configura el "plugin" de AWS para que Terraform sepa con quién hablar.
2. `variables.tf`: Define variables (como la región o el nombre del proyecto) para no tener que escribirlas a fuego en el código (hardcodear).

Finalmente, ejecuté `terraform init` para que Terraform descargara los binarios necesarios de AWS de internet.
