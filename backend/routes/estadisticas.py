"""Estadísticas del censo."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models import User, Vivienda
from schemas.estadisticas import EstadisticasResponse
from utils.auth import get_current_user

router = APIRouter()


@router.get("", response_model=EstadisticasResponse)
def get_estadisticas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total = db.query(func.count(Vivienda.id)).scalar() or 0
    sobre_falla = db.query(func.count(Vivienda.id)).filter(Vivienda.sobre_falla == True).scalar() or 0
    dano_severo = db.query(func.count(Vivienda.id)).filter(
        Vivienda.nivel_dano.in_(["severo", "inhabitable"])
    ).scalar() or 0
    poblacion = db.query(func.coalesce(func.sum(Vivienda.habitantes_total), 0)).scalar() or 0
    return EstadisticasResponse(
        total_viviendas=total,
        viviendas_sobre_falla=sobre_falla,
        viviendas_dano_severo=int(dano_severo),
        poblacion_afectada=int(poblacion),
    )
