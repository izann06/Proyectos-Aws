# 🚀 Evolución de Contenedores en AWS

Este proyecto documenta la progresión natural (y profesional) de cómo se despliegan aplicaciones contenerizadas en la nube de Amazon Web Services. Está diseñado como un viaje de aprendizaje, partiendo de los conceptos más rudimentarios hasta llegar al estándar más moderno del mercado.

Para todas las fases usaremos la misma **API en Python (FastAPI)**, situada en la carpeta `/api`. El objetivo no es cambiar el código de la aplicación, sino evolucionar la infraestructura que la soporta.

## 🗺️ El Roadmap de las 3 Fases

### [Fase 1: EC2 + Docker (Control Manual)](./01_EC2_Docker/README.md)
**El enfoque "Hazlo tú mismo".**
En esta fase aprovisionamos una máquina virtual (Instancia EC2) y, mediante un script de inicio, le instalamos Docker. Usamos GitHub Actions para conectarnos a la máquina por SSH y ejecutar los comandos de Docker.
- **Enseñanza:** Entender los fundamentos, el networking básico y el funcionamiento de Docker y AWS.

### [Fase 2: ECS sobre instancias EC2 (Orquestación Híbrida)](./02_ECS_EC2/README.md)
**Introduciendo a los orquestadores.**
Dejamos de conectarnos por SSH y dejamos de teclear comandos de Docker. Introducimos **AWS ECS (Elastic Container Service)** como nuestro "director de orquesta". ECS gestiona los contenedores, pero nosotros seguimos siendo los dueños de los servidores EC2 físicos donde se ejecutan. 
- **Enseñanza:** Entender qué es un ECR, Roles IAM, Task Definitions y cómo un orquestador automatiza la alta disponibilidad.

### Fase 3: ECS Fargate (100% Serverless) *[En desarrollo...]*
**La nube moderna.**
Eliminamos por completo los servidores EC2. Usamos el motor **AWS Fargate**, donde simplemente entregamos nuestra imagen Docker a Amazon y decimos: *"Dame 1GB de RAM y 0.5 vCPU"*. No hay sistema operativo que parchear, ni máquinas que escalar; todo es Serverless.
- **Enseñanza:** Despliegues de abstracción máxima donde solo pagas por milisegundos de computación real.
