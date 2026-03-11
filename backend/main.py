"""API Censo de Viviendas sobre Fallas Geológicas."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from config import get_settings
from database import engine, Base
from models import User, Vivienda, FotoVivienda, FallaGeologica  # noqa: F401 - register tables
from routes import api_router
from routes.mapa import get_mapa_html

settings = get_settings()
app = FastAPI(title=settings.APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")


@app.get("/api")
def api_root():
    """Respuesta en /api para que no dé 404 al verificar la URL."""
    return {"message": "Censo Viviendas Fallas API", "docs": "/docs", "mapa": "/mapa", "login": "/api/auth/login"}


@app.get("/")
def root():
    return {"app": settings.APP_NAME, "docs": "/docs", "mapa": "/mapa"}


@app.get("/mapa", response_class=HTMLResponse)
def pagina_mapa():
    """Mapa web: fallas y viviendas en el navegador."""
    return HTMLResponse(content=get_mapa_html())


@app.on_event("startup")
def startup():
    """Crear tablas si no existen."""
    try:
        Base.metadata.create_all(bind=engine)
    except Exception:
        pass  # Si falla (ej. sin PostGIS), la app sigue para que /docs y /api respondan
