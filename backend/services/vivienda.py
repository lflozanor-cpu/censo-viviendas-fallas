from sqlalchemy.orm import Session
from uuid import UUID
from models.vivienda import Vivienda
from schemas.vivienda import ViviendaCreate, ViviendaUpdate
from geoalchemy2.elements import WKTElement
from utils.geom import wkt_from_lat_lon
from services.spatial import distancia_minima_a_falla, esta_sobre_falla

# Buffer en metros: hasta esta distancia se considera "sobre falla" (ej. 10 m)
BUFFER_SOBRE_FALLA_M = 10

def _actualizar_distancia_falla(db: Session, db_vivienda: Vivienda, wkt: str):
    dist = distancia_minima_a_falla(db, wkt)
    db_vivienda.distancia_falla = float(dist) if dist is not None else None
    db_vivienda.sobre_falla = esta_sobre_falla(db, wkt, buffer_m=BUFFER_SOBRE_FALLA_M) or False

def crear_vivienda(db: Session, data: ViviendaCreate, inspector_id: UUID):
    geom = None
    wkt = None
    if data.lat is not None and data.lon is not None:
        wkt = wkt_from_lat_lon(data.lat, data.lon)
        geom = WKTElement(wkt, srid=4326)
    
    db_vivienda = Vivienda(
        **data.dict(exclude={'lat', 'lon'}),
        inspector_id=inspector_id,
        geom=geom
    )
    if wkt:
        _actualizar_distancia_falla(db, db_vivienda, wkt)
    db.add(db_vivienda)
    db.commit()
    db.refresh(db_vivienda)
    return db_vivienda

def listar_viviendas(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Vivienda).offset(skip).limit(limit).all()

def obtener_vivienda(db: Session, vivienda_id: UUID):
    return db.query(Vivienda).filter(Vivienda.id == vivienda_id).first()

def actualizar_vivienda(db: Session, vivienda_id: UUID, data: ViviendaUpdate):
    db_vivienda = obtener_vivienda(db, vivienda_id)
    if not db_vivienda:
        return None
    
    update_data = data.dict(exclude_unset=True, exclude={'lat', 'lon'})
    for key, value in update_data.items():
        setattr(db_vivienda, key, value)
    
    if data.lat is not None and data.lon is not None:
        wkt = wkt_from_lat_lon(data.lat, data.lon)
        db_vivienda.geom = WKTElement(wkt, srid=4326)
        _actualizar_distancia_falla(db, db_vivienda, wkt)
    
    db.commit()
    db.refresh(db_vivienda)
    return db_vivienda

def eliminar_vivienda(db: Session, vivienda_id: UUID):
    db_vivienda = obtener_vivienda(db, vivienda_id)
    if db_vivienda:
        db.delete(db_vivienda)
        db.commit()
        return True
    return False

def listar_sobre_falla(db: Session):
    return db.query(Vivienda).filter(Vivienda.sobre_falla == True).all()