"""Crear usuario inspector inicial."""
import sys
from pathlib import Path

backend = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend))

from database import SessionLocal
from models import User
from utils.auth import get_password_hash

def main():
    email = "imbio@pabellon.gob.mx"
    password = "IMBIO2026"
    full_name = "IMBIO Censo"
    db = SessionLocal()
    if db.query(User).filter(User.email == email).first():
        print(f"Usuario {email} ya existe.")
        db.close()
        return
    user = User(
        email=email,
        hashed_password=get_password_hash(password),
        full_name=full_name,
    )
    db.add(user)
    db.commit()
    db.close()
    print(f"Usuario creado: {email}")
    print("  Contraseña: IMBIO2026")

if __name__ == "__main__":
    main()
