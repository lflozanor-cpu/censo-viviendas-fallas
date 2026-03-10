from sqlalchemy.orm import Session
from sqlalchemy import text


def distancia_minima_a_falla(db: Session, vivienda_geom_wkt: str):

    query = text("""
    SELECT MIN(
        ST_Distance(
            ST_GeomFromText(:geom,4326)::geography,
            geom::geography
        )
    )
    FROM fallas_geologicas
    """)

    result = db.execute(query, {"geom": vivienda_geom_wkt}).scalar()

    return result


def esta_sobre_falla(db: Session, vivienda_geom_wkt: str, buffer_m=5):

    query = text("""
    SELECT EXISTS(
        SELECT 1
        FROM fallas_geologicas
        WHERE ST_Intersects(
            ST_Buffer(geom::geography,:buffer)::geometry,
            ST_GeomFromText(:geom,4326)
        )
    )
    """)

    result = db.execute(query, {"geom": vivienda_geom_wkt, "buffer": buffer_m}).scalar()

    return result
