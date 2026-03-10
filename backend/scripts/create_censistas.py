"""Crear varios usuarios censistas para repartir en celulares.

Edita la lista CENSISTAS con (email, contraseña, nombre) y ejecuta:
  python scripts/create_censistas.py

Luego cada celular inicia sesión con su propio email y contraseña.
"""
import sys
from pathlib import Path

backend = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend))

from database import SessionLocal
from models import User
from utils.auth import get_password_hash

# Edita aquí: (email, contraseña, nombre completo)
CENSISTAS = [
    ("censista1@ejemplo.com", "cambiar123", "María García"),
    ("censista2@ejemplo.com", "cambiar123", "Juan Pérez"),
    ("censista3@ejemplo.com", "cambiar123", "Ana López"),
    # Añade más líneas según cuántos celulares/censistas tengas.
]


def main():
    db = SessionLocal()
    try:
        for email, password, full_name in CENSISTAS:
            if db.query(User).filter(User.email == email).first():
                print(f"  Ya existe: {email}")
                continue
            user = User(
                email=email,
                hashed_password=get_password_hash(password),
                full_name=full_name or email.split("@")[0],
            )
            db.add(user)
            db.commit()
            print(f"  Creado: {email} / {password}  ({full_name})")
        print("Listo. Cada celular puede iniciar sesión con su correo y contraseña.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
