"""Modelo de foto de vivienda."""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from database import Base


class FotoVivienda(Base):
    """Evidencia fotográfica de una vivienda."""
    __tablename__ = "fotos_vivienda"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vivienda_id = Column(UUID(as_uuid=True), ForeignKey("viviendas.id", ondelete="CASCADE"), nullable=False)
    tipo_foto = Column(Text, nullable=True)  # fachada, grietas, interior, terreno
    url = Column(Text, nullable=False)
    fecha = Column(DateTime, default=datetime.utcnow)
    geom = Column(Geometry(geometry_type="POINT", srid=4326), nullable=True)

    vivienda = relationship("Vivienda", back_populates="fotos")
