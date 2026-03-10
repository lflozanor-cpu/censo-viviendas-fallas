"""Modelo de falla geológica."""
from datetime import datetime
from sqlalchemy import Column, Integer, Text, DateTime
from geoalchemy2 import Geometry
from database import Base


class FallaGeologica(Base):
    """Falla geológica cargada desde GeoJSON."""
    __tablename__ = "fallas_geologicas"

    id = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(Text, nullable=True)
    tipo_falla = Column(Text, nullable=True)
    geom = Column(Geometry(geometry_type="LINESTRING", srid=4326), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
