"""Rutas API."""
from fastapi import APIRouter
from .auth import router as auth_router
from .viviendas import router as viviendas_router
from .fallas import router as fallas_router
from .estadisticas import router as estadisticas_router
from .export import router as export_router
from .mapa import router as mapa_router

api_router = APIRouter()
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(viviendas_router, prefix="/viviendas", tags=["viviendas"])
api_router.include_router(fallas_router, prefix="/fallas", tags=["fallas"])
api_router.include_router(estadisticas_router, prefix="/estadisticas", tags=["estadisticas"])
api_router.include_router(export_router, prefix="/export", tags=["export"])
api_router.include_router(mapa_router, prefix="/mapa", tags=["mapa"])
