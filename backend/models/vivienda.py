"""Modelo de vivienda censada."""
import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Text, Integer, Boolean, Float, DateTime,
    ForeignKey,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from database import Base


class Vivienda(Base):
    """Vivienda censada."""
    __tablename__ = "viviendas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    fecha_registro = Column(DateTime, default=datetime.utcnow)
    inspector_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    # Datos generales
    nombre_propietario = Column(Text, nullable=True)
    telefono = Column(Text, nullable=True)
    direccion = Column(Text, nullable=True)
    colonia = Column(Text, nullable=True)
    localidad = Column(Text, nullable=True)

    # Datos sociales
    habitantes_total = Column(Integer, default=0)
    ninos = Column(Integer, default=0)
    adultos_mayores = Column(Integer, default=0)
    personas_discapacidad = Column(Integer, default=0)

    # Características estructurales
    tipo_construccion = Column(Text, nullable=True)
    niveles = Column(Integer, default=1)
    anio_construccion = Column(Integer, nullable=True)

    # Daños estructurales (booleanos)
    grietas_muros = Column(Boolean, default=False)
    grietas_piso = Column(Boolean, default=False)
    separacion_muro_techo = Column(Boolean, default=False)
    hundimiento = Column(Boolean, default=False)
    inclinacion = Column(Boolean, default=False)
    fractura_reciente = Column(Boolean, default=False)

    nivel_dano = Column(Text, nullable=True)  # leve, moderado, severo, inhabitable
    observaciones = Column(Text, nullable=True)

    # Geometría y GPS
    geom = Column(Geometry(geometry_type="POINT", srid=4326), nullable=True)
    precision_gps = Column(Float, nullable=True)
    altitud = Column(Float, nullable=True)

    # Resultados análisis espacial
    distancia_falla = Column(Float, nullable=True)
    sobre_falla = Column(Boolean, default=False)
    indice_riesgo_vivienda = Column(Float, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    fotos = relationship("FotoVivienda", back_populates="vivienda", cascade="all, delete-orphan")
