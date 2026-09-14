# Imagen base: Tomo como base la version 3.11 de python, es la que uso en mi maquina local.
#slim: version ligera de python, ocupa menos espacio.
FROM python:3.11-slim 

#Directorio donde se van a guardar todas las dependencias y el codigo de la aplicacion.
WORKDIR /app

#Se copia el archivo requirements.txt a la carpeta /app para poder instalar las dependencias.
COPY requirements.txt .

#Se instalan todas las dependencias y sin guardar cache, para que sea mas rapido.
RUN pip install --no-cache-dir -r requirements.txt

#Se copia el codigo de la aplicacion
COPY . .

#El contenedor está escuchando en el puerto 8080
EXPOSE 8080

#Cuando el contenedor se inicie, se ejecutara este comando.
#El 0.0.0.0 hace que este disponible en cualquier interfaz de red.
CMD ["uvicorn", "main:appIzan", "--host", "0.0.0.0", "--port", "8080"]