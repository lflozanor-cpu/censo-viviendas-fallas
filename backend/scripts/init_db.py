"""Crear tablas y extensión PostGIS."""
import sys
from pathlib import Path

# Asegurar que backend está en el path
backend = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend))

from database import engine, Base
from models import User, Vivienda, FotoVivienda, FallaGeologica

if __name__ == "__main__":
    from sqlalchemy import text
    with engine.connect() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        conn.commit()
    Base.metadata.create_all(bind=engine)
    print("Tablas creadas (users, viviendas, fotos_vivienda, fallas_geologicas).")
