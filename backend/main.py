"""API Censo de Viviendas sobre Fallas Geológicas."""
import traceback
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from sqlalchemy.orm import Session

from config import get_settings
from database import engine, Base, get_db
from models import User, Vivienda, FotoVivienda, FallaGeologica  # noqa: F401 - register tables
from routes import api_router
from routes.mapa import get_mapa_html
from utils.auth import get_password_hash

settings = get_settings()
app = FastAPI(title=settings.APP_NAME)


@app.exception_handler(Exception)
def unhandled_exception_handler(request, exc):
    """Devuelve 500 en JSON con el error para poder depurar en Render."""
    tb = traceback.format_exc()
    print("Unhandled exception:", tb)
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc), "type": type(exc).__name__, "traceback": tb},
    )

EMAIL_IMBIO = "imbio@pabellon.gob.mx"
PASSWORD_IMBIO = "IMBIO2026"
FULL_NAME_IMBIO = "IMBIO Censo"

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


@app.get("/api/reset-imbio")
def reset_imbio(
    secret: str = Query(..., description="Clave RESET_IMBIO_SECRET"),
    db: Session = Depends(get_db),
):
    """Crea o restablece usuario imbio@pabellon.gob.mx / IMBIO2026. Uso: ?secret=TU_CLAVE"""
    s = get_settings()
    if not s.RESET_IMBIO_SECRET or secret != s.RESET_IMBIO_SECRET:
        raise HTTPException(status_code=404, detail="No encontrado")
    try:
        user = db.query(User).filter(User.email == EMAIL_IMBIO).first()
        hashed = get_password_hash(PASSWORD_IMBIO)
        if user:
            user.hashed_password = hashed
            user.full_name = FULL_NAME_IMBIO
            user.is_active = True
            db.commit()
            return {"ok": True, "message": "Contraseña actualizada para " + EMAIL_IMBIO}
        user = User(email=EMAIL_IMBIO, hashed_password=hashed, full_name=FULL_NAME_IMBIO)
        db.add(user)
        db.commit()
        return {"ok": True, "message": "Usuario creado: " + EMAIL_IMBIO}
    except Exception as e:
        db.rollback()
        err = traceback.format_exc()
        print("reset_imbio error:", err)  # Log en Render
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


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
    except Exception as e:
        print("create_all tables warning:", e)  # Log en Render para ver si falla la BD
