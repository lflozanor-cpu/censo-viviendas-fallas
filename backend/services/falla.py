import json
from sqlalchemy.orm import Session
from sqlalchemy import func
from geoalchemy2.shape import to_shape
from geoalchemy2.elements import WKTElement
import shapely.geometry

# Importamos el modelo (Asegúrate de que la ruta sea correcta)
from models.falla_geologica import FallaGeologica

def listar_fallas(db: Session):
    """Retorna todos los registros de fallas en la base de datos."""
    return db.query(FallaGeologica).all()

def obtener_falla(db: Session, falla_id: int):
    """Busca una falla específica por su ID."""
    return db.query(FallaGeologica).filter(FallaGeologica.id == falla_id).first()

def crear_falla(db: Session, falla_data: dict):
    """Crea un nuevo registro de falla geológica."""
    nueva_falla = FallaGeologica(**falla_data)
    db.add(nueva_falla)
    db.commit()
    db.refresh(nueva_falla)
    return nueva_falla

def fallas_con_geometria_geojson(db: Session):
    """Retorna las fallas en formato FeatureCollection de GeoJSON."""
    fallas = db.query(FallaGeologica).all()
    features = []
    
    for falla in fallas:
        # Convertimos la geometría de PostGIS a un objeto Shapely
        geom = to_shape(falla.geom) if falla.geom else None
        
        feature = {
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": list(geom.coords) if geom else []
            },
            "properties": {
                "id": str(falla.id),
                "nombre": falla.nombre,
                "tipo": getattr(falla, "tipo_falla", None) or getattr(falla, "tipo", None)
            }
        }
        features.append(feature)
        
    return {"type": "FeatureCollection", "features": features}

def fallas_buffers(db: Session, metros: float = 50.0):
    """
    Genera polígonos de zona de influencia alrededor de las fallas.
    Utiliza funciones nativas de PostGIS para precisión geográfica.
    """
    # ST_Buffer crea el área, ST_AsGeoJSON la convierte a texto JSON
    fallas_query = db.query(
        FallaGeologica.id,
        FallaGeologica.nombre,
        func.ST_AsGeoJSON(func.ST_Buffer(FallaGeologica.geom, metros)).label("geom_json")
    ).all()
    
    features = []
    for f in fallas_query:
        features.append({
            "type": "Feature",
            "geometry": json.loads(f.geom_json),
            "properties": {
                "id": f.id, 
                "nombre": f.nombre, 
                "buffer_metros": metros
            }
        })
    return {"type": "FeatureCollection", "features": features}

def importar_geojson(db: Session, geojson_data: dict):
    """
    Procesa un archivo GeoJSON y guarda las geometrías como fallas.
    """
    count = 0
    for feature in geojson_data.get("features", []):
        geometry = feature.get("geometry")
        if not geometry or geometry["type"] != "LineString":
            continue
            
        coords = geometry["coordinates"]
        line = shapely.geometry.LineString(coords)
        
        props = feature.get("properties") or {}
        nueva_falla = FallaGeologica(
            nombre=props.get("nombre", f"Falla_{count}"),
            tipo_falla=props.get("tipo", props.get("tipo_falla", "Desconocido")),
            geom=WKTElement(line.wkt, srid=4326)
        )
        db.add(nueva_falla)
        count += 1
            
    db.commit()
    return {"status": "success", "imported_count": count}