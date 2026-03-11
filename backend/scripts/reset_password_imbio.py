"""
Crear o restablecer la contraseña del usuario imbio@pabellon.gob.mx a IMBIO2026.

OPCIÓN SIN SHELL (recomendada si no tienes Shell en Render):
  1. En Render → tu servicio → Environment: añade RESET_IMBIO_SECRET = una_clave_secreta (ej: censo2026reset).
  2. Sube el código que incluye la ruta /api/auth/reset-imbio y haz deploy.
  3. En el navegador abre: https://censo-api.onrender.com/api/auth/reset-imbio?secret=una_clave_secreta
  4. Deberías ver {"ok": true, "message": "Usuario creado: ..."} o "Contraseña actualizada...".
  5. (Opcional) Borra RESET_IMBIO_SECRET de Environment y vuelve a desplegar.

Local (con DATABASE_URL de Render en .env):
  cd backend && python scripts/reset_password_imbio.py
"""
import os
import sys
from pathlib import Path

backend = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend))

# Cargar variables de entorno (Render las inyecta)
from database import SessionLocal
from models import User
from utils.auth import get_password_hash

EMAIL = "imbio@pabellon.gob.mx"
PASSWORD = "IMBIO2026"
FULL_NAME = "IMBIO Censo"


def main():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == EMAIL).first()
        hashed = get_password_hash(PASSWORD)
        if user:
            user.hashed_password = hashed
            user.full_name = FULL_NAME
            user.is_active = True
            db.commit()
            print(f"Contraseña actualizada para: {EMAIL}")
        else:
            user = User(
                email=EMAIL,
                hashed_password=hashed,
                full_name=FULL_NAME,
            )
            db.add(user)
            db.commit()
            print(f"Usuario creado: {EMAIL}")
        print("  Contraseña: IMBIO2026")
    finally:
        db.close()


if __name__ == "__main__":
    main()
