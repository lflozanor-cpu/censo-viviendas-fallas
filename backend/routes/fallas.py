"""Fallas geológicas: listado, buffer, upload GeoJSON."""
import json
from pathlib import Path
from fastapi import APIRouter, Depends, UploadFile, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User
from utils.auth import get_current_user
from services.falla import (
    listar_fallas,
    fallas_con_geometria_geojson,
    fallas_buffers,
    importar_geojson,
)

router = APIRouter()

ALLOWED_EXTENSIONS = {".geojson", ".json"}


@router.post("/upload_geojson")
def upload_geojson(
    file: UploadFile,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Carga archivo .geojson o .json y registra fallas en PostGIS."""
    suf = Path(file.filename or "").suffix.lower()
    if suf not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Solo se permiten .geojson o .json")
    content = file.file.read()
    try:
        data_str = content.decode("utf-8")
    except Exception:
        raise HTTPException(status_code=400, detail="Archivo debe ser texto UTF-8")
    try:
        geojson_data = json.loads(data_str)
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"GeoJSON inválido: {e}")
    try:
        result = importar_geojson(db, geojson_data)
        count = result.get("imported_count", 0)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"importadas": count}


@router.get("")
def get_fallas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return listar_fallas(db)


@router.get("/geojson")
def get_fallas_geojson(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """GeoJSON FeatureCollection con las líneas de las fallas geológicas."""
    return fallas_con_geometria_geojson(db)


@router.get("/buffer")
def get_fallas_buffer(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Zonas: 5m ruptura, 20m fractura, 50m deformación."""
    return fallas_buffers(db, radios_metros=[5, 20, 50])
