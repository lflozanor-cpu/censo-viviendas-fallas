"""Esquemas de foto."""
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel


class FotoViviendaCreate(BaseModel):
    vivienda_id: UUID
    tipo_foto: str  # fachada, grietas, interior, terreno
    url: str
    lat: float | None = None
    lon: float | None = None


class FotoViviendaResponse(BaseModel):
    id: int
    vivienda_id: int
    tipo_foto: str | None
    url: str
    fecha: datetime
    lat: float | None = None
    lon: float | None = None

    class Config:
        from_attributes = True
