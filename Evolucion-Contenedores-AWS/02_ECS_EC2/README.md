# 🚢 Fase 2: AWS ECS sobre EC2 (Orquestación de Contenedores)

> **Objetivo:** Evolucionar desde un servidor con EC2 y docker a mano (Fase 1) hacia una arquitectura **auto-gestionada** donde un orquestador se encarga de mantener viva mi aplicación sin que yo tenga que intervenir nunca.

---

## 🎯 ¿Por qué esta Fase? Problemas que resuelve respecto a la Fase 1

| Problema en Fase 1 | Solución en Fase 2 |
|---|---|
| Si el contenedor moría, se quedaba muerto para siempre | ECS Service lo detecta y lo reinicia en segundos |
| Compilar la imagen en el propio servidor de producción (lento y peligroso) | La imagen se compila en GitHub Actions y se guarda en ECR |
| Conectarse por SSH al servidor para hacer cambios (mala práctica) | GitHub Actions empuja la imagen a ECR y avisa a ECS, nadie toca el servidor |
| Un solo servidor: si falla, todo cae | Auto Scaling Group: si un servidor cae, fabrica uno nuevo automáticamente |

---

## ⚙️ Diccionario de Piezas: ¿Para qué sirve cada cosa?

### 🏭 ECR (Elastic Container Registry)
Es el **almacén privado de imágenes Docker** de Amazon. Funciona igual que Docker Hub, pero dentro de mi cuenta de AWS.
- Guarda las imágenes ya construidas y empaquetadas de mi aplicación.
- El orquestador (ECS) acude aquí a descargar la imagen cuando necesita arrancar un contenedor nuevo.
- Yo nunca construyo (`docker build`) en el servidor de producción. Solo lo hago una vez en GitHub Actions y guardo el resultado aquí.

### 🎮 ECS (Elastic Container Service) — El Orquestador
Es el **cerebro central**. Se encarga de saber cuántos contenedores están vivos, dónde están y cuándo hay que reiniciarlos. Le doy una orden (`desired_count = 1`) y se encarga de que se  siempre haya 1 contenedor funcionando, sin importar lo que pase.

### 📋 Task Definition — La Receta
Es el equivalente a escribir `docker run` a mano, pero en formato de documento de configuración. Le dice a ECS exactamente cómo arrancar mi contenedor:
- ¿Qué imagen usar? → La del ECR.
- ¿Cuánta RAM? → 256MB.
- ¿Qué puerto exponer? → 8080.

### 👮 ECS Service — El Vigilante
Usa la Task Definition (la receta) y recibe una orden permanente: *"Asegúrate de que siempre haya 1 contenedor vivo."* Si el contenedor muere por un error, el Vigilante lo detecta y le dice al ECS que arranque uno nuevo usando la receta.

### 🪪 IAM Roles — Los Carnets de Identidad
En AWS nadie puede hacer nada sin un carnet. El servidor EC2 necesita un carnet (roles) para poder descargar imágenes del ECR. Sin él, Amazon le daría un "Access Denied" aunque la infraestructura esté perfecta.

### 🖥️ EC2 + Auto Scaling Group — Los Servidores Esclavos
La máquina física donde ECS coloca los contenedores. En lugar de crear un servidor suelto (Fase 1), creo un **molde** (Launch Template) y una **fábrica** (Auto Scaling Group) que garantiza que siempre habrá al menos 1 servidor encendido. Si se apaga o se rompe, la fábrica crea uno nuevo automáticamente.

### 🤖 GitHub Actions — El Robot de Despliegue
El robot se activa cada vez que hago un `git push` con cambios en la carpeta `/api` o hago el workflow a mano en la web de github. Se encarga de construir la imagen Docker, subirla al ECR y avisarle al orquestador ECS que hay una versión nueva lista para arrancar. Por lo que si cambio código agrego algo nuevo al Dockerfile etc, el robot se encarga de actualizarlo.

Para ello, el robot tiene que tener los roles de IAM para poder acceder al ECR y al ECS. Se le dan los permisos necesarios al robot con variables de entorno en la configuración de github (Settings -> Secrets and variables -> Actions y New repository secret). Estas variables son AWS_ACCESS_KEY_ID (pública, ya que es un id de un usuario de IAM), AWS_SECRET_ACCESS_KEY (privada, es la contraseña), de un usuario de IAM.

---

## 🗺️ Diagrama Visual: El Flujo Completo

```
 MI ORDENADOR                GITHUB                        AWS
 ─────────────           ─────────────              ──────────────────────────────────────────
                                                    
  Escribo código  ──push──►  Repositorio
                             GitHub
                                │
                                │ Detecta cambios en /api
                                │
                                ▼
                          GitHub Actions
                          (Robot Ubuntu)
                                │
                    ┌───────────┼───────────────────┐
                    │           │                   │
                    │    1. docker build             │
                    │    (Cocina la imagen)          │
                    │           │                   │
                    │    2. docker push              │
                    │           │                   │
                    │           ▼                   │
                    │     ┌──────────┐              │
                    │     │   ECR    │              │
                    │     │Congelador│              │
                    │     │de imágen │              │
                    │     └────┬─────┘              │
                    │          │                    │
                    │    3. aws ecs update-service   │
                    │          │                    │
                    └──────────┼────────────────────┘
                               │
                               ▼
                        ┌────────────┐
                        │ECS Service │ ◄── IAM Role (Carnet de permisos)
                        │(Vigilante) │
                        └─────┬──────┘
                              │ Lee la Task Definition (Receta)
                              │ Va al ECR a buscar la imagen nueva
                              ▼
                        ┌────────────┐
                        │ ECS Cluster│
                        │  (Tablero) │
                        └─────┬──────┘
                              │ Coloca el contenedor en
                              ▼
                        ┌────────────┐
                        │Auto Scaling│
                        │  Group     │
                        │ ┌────────┐ │
                        │ │  EC2   │ │ ◄── IAM Role (Carnet de permisos)
                        │ │  t2.   │ │
                        │ │ micro  │ │
                        │ │[Docker]│ │
                        │ └────────┘ │
                        └────────────┘
                              │
                              ▼
                     http://IP_PUBLICA:8080
                     ¡API accesible! 🎉
```

**En resumen cronológico:**
`git push` → `GitHub Actions` construye imagen → sube a `ECR` → avisa a `ECS Service` → ECS descarga imagen del `ECR` → arranca contenedor en `EC2`

---

## 👍 Ventajas respecto a la Fase 1

- **Auto-recuperación (Self-healing):** Si el contenedor muere, ECS levanta otro en segundos sin que yo haga nada.
- **Despliegues sin cortes (Rolling Update):** Cuando subo código nuevo, ECS arranca el contenedor nuevo antes de matar el viejo. La API nunca está caída durante un despliegue.
- **Compilación limpia:** La imagen Docker se construye en GitHub Actions (un ordenador limpio y potente), no en el servidor de producción.
- **Sin SSH:** Nadie necesita conectarse al servidor. Todo se gestiona a través del orquestador.
- **Escalabilidad:** Si hay mucho tráfico, solo tengo que cambiar `max_size = 2` por un número mayor en el Auto Scaling Group.

## 👎 Inconvenientes que aún existen (Motivación para la Fase 3)

- **Sigo siendo dueño del hardware:** El servidor EC2 es mío. Si el disco duro se llena o el sistema operativo Ubuntu falla a nivel de kernel, la máquina muere y tengo que gestionarlo yo.
- **El servidor está encendido 24/7:** Aunque no haya ningún usuario usando la API a las 3 de la mañana, el EC2 sigue costando dinero.

---

## 🚀 Cómo probarlo desde cero

Sigue estos pasos en orden. Cada sección corresponde a una herramienta diferente.

### Prerequisitos
- Tener [Terraform](https://developer.hashicorp.com/terraform/install) instalado.
- Tener [AWS CLI](https://aws.amazon.com/cli/) instalado y configurado (`aws configure`).
- Tener una llave SSH en `~/.ssh/aws_ubuntu_key` (o crear una nueva con `ssh-keygen`).

### Paso 1: Configurar los secretos de GitHub

Ve a tu repositorio en GitHub → **Settings → Secrets and variables → Actions** y crea estos secretos:

| Nombre del Secreto | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Tu Access Key de AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | Tu Secret Key de AWS IAM |

> **¿Dónde consigo las llaves de AWS?** Ve a la consola de AWS → IAM → Users → Crea un usuario llamado `github-actions-robot` → Dale las políticas `AmazonEC2ContainerRegistryPowerUser` y `AmazonECS_FullAccess` → En la pestaña "Security credentials" → "Create access key".

### Paso 2: Desplegar la infraestructura con Terraform

Abre tu terminal y navega a la carpeta de esta fase:

```bash
cd Evolucion-Contenedores-AWS/02_ECS_EC2

# Descarga los plugins de AWS para Terraform
terraform init

# Revisa qué va a crear (sin crear nada todavía)
terraform plan

# Crea toda la infraestructura en AWS (ECR, IAM, Cluster, EC2, etc.)
terraform apply
```

Escribe `yes` cuando Terraform te lo pida. Al terminar, tendrás toda la infraestructura creada en AWS.

### Paso 3: Lanzar el primer despliegue

Ve a Setting > Pages y en Build and Deployment pon GitHub Actions.

Después, ve a la pestaña **Actions** de tu repositorio en GitHub, busca el workflow llamado **"Fase 2: Despliegue a ECS"** y haz clic en **Run workflow → Run workflow**.

El robot hará automáticamente:
1. Construir la imagen Docker.
2. Subirla al ECR.
3. Decirle a ECS que reinicie con la nueva imagen.

### Paso 4: Ver tu API funcionando

Una vez que el workflow haya terminado (tick verde ✅), ve a tu consola de AWS:
1. Busca el servicio **EC2**.
2. En el menú izquierdo → **Instances**.
3. Copia la **Public IPv4 address** de la instancia que se haya creado.
4. Abre tu navegador en `http://TU_IP:8080`.

¡Tu API estará corriendo gestionada por ECS! 🎉

### Paso 5 (Limpieza): Destruir la infraestructura

Para no acumular costes cuando no estés usando el proyecto:

```bash
cd Evolucion-Contenedores-AWS/02_ECS_EC2
terraform destroy
```

Escribe `yes` y Terraform eliminará todos los recursos de AWS que creó.
