"""Conexión a base de datos PostgreSQL con PostGIS."""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.event import listen
from config import get_settings

settings = get_settings()

# Render y otros clouds requieren SSL; postgres:// -> postgresql:// para SQLAlchemy
database_url = settings.DATABASE_URL
if database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql://", 1)
if ("render.com" in database_url or "localhost" not in database_url) and "sslmode" not in database_url:
    database_url += "?sslmode=require" if "?" not in database_url else "&sslmode=require"

engine = create_engine(
    database_url,
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
