"""Esquemas de vivienda."""
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field
from typing import Any


class Coordenadas(BaseModel):
    lat: float
    lon: float
    altitud: float | None = None
    precision_gps: float | None = None


class ViviendaCreate(BaseModel):
    nombre_propietario: str | None = None
    telefono: str | None = None
    direccion: str | None = None
    colonia: str | None = None
    localidad: str | None = None
    habitantes_total: int = 0
    ninos: int = 0
    adultos_mayores: int = 0
    personas_discapacidad: int = 0
    tipo_construccion: str | None = None
    niveles: int = 1
    anio_construccion: int | None = None
    grietas_muros: bool = False
    grietas_piso: bool = False
    separacion_muro_techo: bool = False
    hundimiento: bool = False
    inclinacion: bool = False
    fractura_reciente: bool = False
    nivel_dano: str | None = None
    observaciones: str | None = None
    lat: float | None = None
    lon: float | None = None
    altitud: float | None = None
    precision_gps: float | None = None

    class Config:
        from_attributes = True


class ViviendaUpdate(BaseModel):
    nombre_propietario: str | None = None
    telefono: str | None = None
    direccion: str | None = None
    colonia: str | None = None
    localidad: str | None = None
    habitantes_total: int | None = None
    ninos: int | None = None
    adultos_mayores: int | None = None
    personas_discapacidad: int | None = None
    tipo_construccion: str | None = None
    niveles: int | None = None
    anio_construccion: int | None = None
    grietas_muros: bool | None = None
    grietas_piso: bool | None = None
    separacion_muro_techo: bool | None = None
    hundimiento: bool | None = None
    inclinacion: bool | None = None
    fractura_reciente: bool | None = None
    nivel_dano: str | None = None
    observaciones: str | None = None
    lat: float | None = None
    lon: float | None = None
    altitud: float | None = None
    precision_gps: float | None = None


class ViviendaResponse(BaseModel):
    id: UUID
    fecha_registro: datetime
    inspector_id: UUID | None
    nombre_propietario: str | None
    telefono: str | None
    direccion: str | None
    colonia: str | None
    localidad: str | None
    habitantes_total: int
    ninos: int
    adultos_mayores: int
    personas_discapacidad: int
    tipo_construccion: str | None
    niveles: int
    anio_construccion: int | None
    grietas_muros: bool
    grietas_piso: bool
    separacion_muro_techo: bool
    hundimiento: bool
    inclinacion: bool
    fractura_reciente: bool
    nivel_dano: str | None
    observaciones: str | None
    lat: float | None = None
    lon: float | None = None
    precision_gps: float | None
    altitud: float | None
    distancia_falla: float | None
    sobre_falla: bool
    indice_riesgo_vivienda: float | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_with_geom(cls, obj: Any) -> "ViviendaResponse":
        data = {
            "id": obj.id,
            "fecha_registro": obj.fecha_registro,
            "inspector_id": obj.inspector_id,
            "nombre_propietario": obj.nombre_propietario,
            "telefono": obj.telefono,
            "direccion": obj.direccion,
            "colonia": obj.colonia,
            "localidad": obj.localidad,
            "habitantes_total": obj.habitantes_total,
            "ninos": obj.ninos,
            "adultos_mayores": obj.adultos_mayores,
            "personas_discapacidad": obj.personas_discapacidad,
            "tipo_construccion": obj.tipo_construccion,
            "niveles": obj.niveles,
            "anio_construccion": obj.anio_construccion,
            "grietas_muros": obj.grietas_muros,
            "grietas_piso": obj.grietas_piso,
            "separacion_muro_techo": obj.separacion_muro_techo,
            "hundimiento": obj.hundimiento,
            "inclinacion": obj.inclinacion,
            "fractura_reciente": obj.fractura_reciente,
            "nivel_dano": obj.nivel_dano,
            "observaciones": obj.observaciones,
            "precision_gps": obj.precision_gps,
            "altitud": obj.altitud,
            "distancia_falla": obj.distancia_falla,
            "sobre_falla": obj.sobre_falla,
            "indice_riesgo_vivienda": obj.indice_riesgo_vivienda,
            "created_at": obj.created_at,
            "updated_at": obj.updated_at,
        }
        if obj.geom:
            from geoalchemy2.shape import to_shape
            pt = to_shape(obj.geom)
            data["lon"] = pt.x
            data["lat"] = pt.y
        else:
            data["lat"] = None
            data["lon"] = None
        return cls(**data)


class ViviendaGeoJSONFeature(BaseModel):
    type: str = "Feature"
    geometry: dict
    properties: dict
