"""Conexión a base de datos PostgreSQL con PostGIS."""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.event import listen
from config import get_settings

settings = get_settings()

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    echo=settings.DEBUG,
)

# Habilitar extensión PostGIS en conexiones (opcional: si falla, la app sigue)
def load_postgis_extension(dbapi_conn, connection_record):
    cursor = dbapi_conn.cursor()
    try:
        cursor.execute("CREATE EXTENSION IF NOT EXISTS postgis")
        dbapi_conn.commit()
    except Exception:
        pass  # PostGIS no disponible (ej. Render); la app arranca igual
    finally:
        cursor.close()

listen(engine, "connect", load_postgis_extension)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependencia para obtener sesión de base de datos."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
