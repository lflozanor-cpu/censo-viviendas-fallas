"""Esquemas de falla geológica."""
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel
from typing import Any


class FallaGeologicaResponse(BaseModel):
    id: UUID
    nombre: str | None
    tipo_falla: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class FallaConGeom(BaseModel):
    id: UUID
    nombre: str | None
    tipo_falla: str | None
    geom_geojson: dict | None = None
    created_at: datetime
