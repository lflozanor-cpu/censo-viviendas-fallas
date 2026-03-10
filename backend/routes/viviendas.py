"""CRUD viviendas y GeoJSON sobre falla."""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from geoalchemy2.shape import to_shape
from geoalchemy2.elements import WKTElement
from database import get_db
from models import User, FotoVivienda
from schemas.vivienda import ViviendaCreate, ViviendaUpdate, ViviendaResponse
from schemas.foto import FotoViviendaCreate, FotoViviendaResponse
from utils.auth import get_current_user
from utils.geom import wkt_from_lat_lon
from services.vivienda import (
    crear_vivienda,
    listar_viviendas,
    obtener_vivienda,
    actualizar_vivienda,
    eliminar_vivienda,
    listar_sobre_falla,
)

router = APIRouter()


def _vivienda_to_geojson_feature(v):
    geom = to_shape(v.geom) if v.geom else None
    return {
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [geom.x, geom.y] if geom else None,
        } if geom else None,
        "properties": {
            "id": str(v.id),
            "nombre_propietario": v.nombre_propietario,
            "direccion": v.direccion,
            "sobre_falla": v.sobre_falla,
            "distancia_falla": v.distancia_falla,
            "nivel_dano": v.nivel_dano,
            "indice_riesgo_vivienda": v.indice_riesgo_vivienda,
            "habitantes_total": v.habitantes_total,
        },
    }


@router.post("", response_model=ViviendaResponse)
def post_vivienda(
    data: ViviendaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    v = crear_vivienda(db, data, inspector_id=current_user.id)
    return ViviendaResponse.from_orm_with_geom(v)


@router.get("", response_model=list[ViviendaResponse])
def get_viviendas(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = listar_viviendas(db, skip=skip, limit=limit)
    return [ViviendaResponse.from_orm_with_geom(v) for v in items]


@router.get("/sobre_falla")
def get_viviendas_sobre_falla(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """GeoJSON FeatureCollection de viviendas con sobre_falla=True."""
    items = listar_sobre_falla(db)
    features = [_vivienda_to_geojson_feature(v) for v in items]
    return {"type": "FeatureCollection", "features": features}


@router.get("/{id}", response_model=ViviendaResponse)
def get_vivienda(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    v = obtener_vivienda(db, id)
    if not v:
        raise HTTPException(status_code=404, detail="Vivienda no encontrada")
    return ViviendaResponse.from_orm_with_geom(v)


@router.put("/{id}", response_model=ViviendaResponse)
def put_vivienda(
    id: UUID,
    data: ViviendaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    v = actualizar_vivienda(db, id, data)
    if not v:
        raise HTTPException(status_code=404, detail="Vivienda no encontrada")
    return ViviendaResponse.from_orm_with_geom(v)


@router.delete("/{id}", status_code=204)
def delete_vivienda(
    id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not eliminar_vivienda(db, id):
        raise HTTPException(status_code=404, detail="Vivienda no encontrada")


@router.post("/{id}/fotos", response_model=FotoViviendaResponse)
def add_foto_vivienda(
    id: UUID,
    data: FotoViviendaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    v = obtener_vivienda(db, id)
    if not v:
        raise HTTPException(status_code=404, detail="Vivienda no encontrada")
    geom = None
    if data.lat is not None and data.lon is not None:
        geom = WKTElement(wkt_from_lat_lon(data.lat, data.lon), srid=4326)
    foto = FotoVivienda(
        vivienda_id=id,
        tipo_foto=data.tipo_foto,
        url=data.url,
        geom=geom,
    )
    db.add(foto)
    db.commit()
    db.refresh(foto)
    return FotoViviendaResponse(
        id=foto.id,
        vivienda_id=foto.vivienda_id,
        tipo_foto=foto.tipo_foto,
        url=foto.url,
        fecha=foto.fecha,
        lat=data.lat,
        lon=data.lon,
    )
