"""Exportación: Excel, GeoJSON, KMZ, viviendas sobre falla."""
import io
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from geoalchemy2.shape import to_shape
from database import get_db
from models import User, Vivienda
from utils.auth import get_current_user
from services.vivienda import listar_viviendas, listar_sobre_falla

router = APIRouter()


def _vivienda_row(v):
    pt = to_shape(v.geom) if v.geom else None
    return {
        "id": str(v.id),
        "nombre_propietario": v.nombre_propietario,
        "telefono": v.telefono,
        "direccion": v.direccion,
        "colonia": v.colonia,
        "localidad": v.localidad,
        "habitantes_total": v.habitantes_total,
        "ninos": v.ninos,
        "adultos_mayores": v.adultos_mayores,
        "personas_discapacidad": v.personas_discapacidad,
        "tipo_construccion": v.tipo_construccion,
        "niveles": v.niveles,
        "anio_construccion": v.anio_construccion,
        "grietas_muros": v.grietas_muros,
        "grietas_piso": v.grietas_piso,
        "separacion_muro_techo": v.separacion_muro_techo,
        "hundimiento": v.hundimiento,
        "inclinacion": v.inclinacion,
        "fractura_reciente": v.fractura_reciente,
        "nivel_dano": v.nivel_dano,
        "observaciones": v.observaciones,
        "lat": pt.y if pt else None,
        "lon": pt.x if pt else None,
        "altitud": v.altitud,
        "precision_gps": v.precision_gps,
        "distancia_falla": v.distancia_falla,
        "sobre_falla": v.sobre_falla,
        "indice_riesgo_vivienda": v.indice_riesgo_vivienda,
    }


def _to_geojson_features(viviendas):
    features = []
    for v in viviendas:
        pt = to_shape(v.geom) if v.geom else None
        features.append({
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [pt.x, pt.y]} if pt else None,
            "properties": _vivienda_row(v),
        })
    return {"type": "FeatureCollection", "features": features}


@router.get("/excel")
def export_excel(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Exportar todas las viviendas a Excel."""
    try:
        import openpyxl
    except ImportError:
        raise HTTPException(status_code=500, detail="Instalar openpyxl para exportar Excel")
    viviendas = listar_viviendas(db, skip=0, limit=10000)
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Viviendas"
    if viviendas:
        headers = list(_vivienda_row(viviendas[0]).keys())
        ws.append(headers)
        for v in viviendas:
            ws.append(list(_vivienda_row(v).values()))
    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=viviendas.xlsx"},
    )


@router.get("/geojson")
def export_geojson(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    viviendas = listar_viviendas(db, skip=0, limit=10000)
    return _to_geojson_features(viviendas)


@router.get("/kmz")
def export_kmz(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Exportar a KMZ (KML comprimido)."""
    try:
        import simplekml
    except ImportError:
        raise HTTPException(status_code=500, detail="Instalar simplekml para exportar KMZ")
    viviendas = listar_viviendas(db, skip=0, limit=10000)
    kml = simplekml.Kml()
    for v in viviendas:
        pt = to_shape(v.geom) if v.geom else None
        if not pt:
            continue
        p = kml.newpoint(
            name=v.nombre_propietario or str(v.id),
            coords=[(pt.x, pt.y)],
            description=f"Daño: {v.nivel_dano}; Sobre falla: {v.sobre_falla}; Distancia: {v.distancia_falla}m",
        )
    buf = io.BytesIO()
    kml.savekmz(buf)
    buf.seek(0)
    return StreamingResponse(
        buf,
        media_type="application/vnd.google-earth.kmz",
        headers={"Content-Disposition": "attachment; filename=viviendas.kmz"},
    )


@router.get("/viviendas_sobre_falla")
def export_viviendas_sobre_falla(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """GeoJSON solo de viviendas sobre falla (coordenadas, daños, distancia)."""
    viviendas = listar_sobre_falla(db)
    return _to_geojson_features(viviendas)
