"""Utilidades de geometría WKT para PostGIS."""
from typing import Optional


def wkt_from_lat_lon(lat: float, lon: float) -> str:
    """Genera WKT Point para SRID 4326 (lon, lat)."""
    return f"SRID=4326;POINT({lon} {lat})"


def wkt_point(lon: float, lat: float, srid: int = 4326) -> str:
    return f"SRID={srid};POINT({lon} {lat})"
