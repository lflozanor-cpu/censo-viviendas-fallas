"""Esquemas de estadísticas."""
from pydantic import BaseModel


class EstadisticasResponse(BaseModel):
    total_viviendas: int
    viviendas_sobre_falla: int
    viviendas_dano_severo: int
    poblacion_afectada: int
