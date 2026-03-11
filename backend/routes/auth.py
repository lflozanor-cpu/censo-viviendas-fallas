"""Autenticación: registro y login JWT."""
import bcrypt
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from config import get_settings
from database import get_db
from models import User
from schemas.user import UserCreate, UserLogin, UserResponse, Token
from utils.auth import get_password_hash, verify_password, create_access_token

router = APIRouter()
EMAIL_IMBIO = "imbio@pabellon.gob.mx"
PASSWORD_IMBIO = "IMBIO2026"
FULL_NAME_IMBIO = "IMBIO Censo"


@router.post("/register", response_model=UserResponse)
def register(data: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email ya registrado")
    user = User(
        email=data.email,
        hashed_password=get_password_hash(data.password),
        full_name=data.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Usuario inactivo")
    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token, user=UserResponse.model_validate(user))


@router.get("/reset-imbio")
def reset_imbio(
    secret: str = Query(..., description="Clave definida en RESET_IMBIO_SECRET"),
    db: Session = Depends(get_db),
):
    """
    Crea o restablece el usuario imbio@pabellon.gob.mx con contraseña IMBIO2026.
    Solo funciona si en el servidor está definida la variable RESET_IMBIO_SECRET y coincide con ?secret=...
    Uso: https://tu-api.onrender.com/api/auth/reset-imbio?secret=TU_CLAVE
    """
    settings = get_settings()
    if not settings.RESET_IMBIO_SECRET or secret != settings.RESET_IMBIO_SECRET:
        raise HTTPException(status_code=404, detail="No encontrado")
    user = db.query(User).filter(User.email == EMAIL_IMBIO).first()
    # Usar bcrypt directo para evitar límite 72 bytes de passlib
    hashed = bcrypt.hashpw(b"IMBIO2026", bcrypt.gensalt()).decode("utf-8")
    if user:
        user.hashed_password = hashed
        user.full_name = FULL_NAME_IMBIO
        user.is_active = True
        db.commit()
        return {"ok": True, "message": "Contraseña actualizada para " + EMAIL_IMBIO}
    user = User(
        email=EMAIL_IMBIO,
        hashed_password=hashed,
        full_name=FULL_NAME_IMBIO,
    )
    db.add(user)
    db.commit()
    return {"ok": True, "message": "Usuario creado: " + EMAIL_IMBIO}
