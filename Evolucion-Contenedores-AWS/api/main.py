from fastapi import FastAPI # Importo la libreria FastAPI para poder crear la API web

# Inicializo la API, esta parte es visible en: http://[IP_ADDRESS]/docs
appIzan = FastAPI(
    title ="Bienvenido/a a los endpoints de mi API",
    description = "API web simple realizado como proyecto para practicar Docker, Terraform, GitHub Actions, AWS...",
    version = "1.0"
    
)

# Endpoint raíz. Cuando alguien entra a "http://[IP_ADDRESS]/", esta función se ejecuta.
@appIzan.get("/")
def raiz():
    return {"message":"Hola, estoy ejecutando un servidor con FastAPI en AWS gracias por probarlo :D"}

# Endpoint de salud: Cuando alguien entra a "http://[IP_ADDRESS]/health", esta función se ejecuta.
# Esta funcion es usada para verificar si el servidor esta funcionando correctamente por GitHub Actions.
@appIzan.get("/health")
def health():
    return {"status": "ok"}

    
