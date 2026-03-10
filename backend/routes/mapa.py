"""Rutas públicas del mapa (sin auth) para ver fallas y viviendas en el navegador."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pathlib import Path

from database import get_db
from services.falla import fallas_con_geometria_geojson
from services.vivienda import listar_viviendas

router = APIRouter()


def _vivienda_geojson_feature(v):
    from geoalchemy2.shape import to_shape
    pt = to_shape(v.geom) if v.geom else None
    if not pt:
        return None
    return {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [pt.x, pt.y]},
        "properties": {
            "id": str(v.id),
            "nombre_propietario": v.nombre_propietario,
            "direccion": v.direccion,
            "colonia": v.colonia,
            "sobre_falla": v.sobre_falla,
            "distancia_falla": v.distancia_falla,
            "nivel_dano": v.nivel_dano,
            "habitantes_total": v.habitantes_total,
        },
    }


@router.get("/fallas/geojson")
def get_fallas_geojson(db: Session = Depends(get_db)):
    """GeoJSON de fallas (público para el mapa web)."""
    return fallas_con_geometria_geojson(db)


@router.get("/viviendas/geojson")
def get_viviendas_geojson(db: Session = Depends(get_db)):
    """GeoJSON de viviendas (público para el mapa web)."""
    viviendas = listar_viviendas(db, skip=0, limit=5000)
    features = []
    for v in viviendas:
        f = _vivienda_geojson_feature(v)
        if f:
            features.append(f)
    return {"type": "FeatureCollection", "features": features}


def _get_mapa_html() -> str:
    """Contenido HTML del mapa (Leaflet + capas)."""
    p = Path(__file__).resolve().parent.parent / "static" / "mapa.html"
    if p.exists():
        return p.read_text(encoding="utf-8")
    return _mapa_html_inline()


def _mapa_html_inline() -> str:
    return """<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Mapa - Censo Viviendas Fallas</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; }
    #map { width: 100vw; height: 100vh; }
    .leyenda { position: absolute; bottom: 24px; left: 12px; z-index: 1000;
      background: #fff; padding: 10px 14px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      font-size: 12px; }
    .leyenda h3 { margin-bottom: 6px; font-size: 13px; }
    .leyenda div { margin: 4px 0; }
    .leyenda .rojo { color: #c62828; }
    .leyenda .naranja { color: #e65100; }
    .leyenda .verde { color: #2e7d32; }
    .cargando { position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%);
      z-index: 1001; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 12px rgba(0,0,0,0.2); }
  </style>
</head>
<body>
  <div id="map"></div>
  <div id="cargando" class="cargando">Cargando mapa...</div>
  <div class="leyenda" id="leyenda" style="display:none;">
    <h3>Leyenda</h3>
    <div><strong>—</strong> Fallas geológicas</div>
    <div class="rojo">● Vivienda crítica (sobre falla / &lt;10 m)</div>
    <div class="naranja">● Vivienda alta/media (10–50 m)</div>
    <div class="verde">● Vivienda baja (&gt;50 m)</div>
  </div>
  <script>
    const map = L.map('map').setView([22.0, -102.0], 5);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(map);

    const api = window.location.origin;
    const fallasUrl = api + '/api/mapa/fallas/geojson';
    const viviendasUrl = api + '/api/mapa/viviendas/geojson';

    function colorVivienda(props) {
      if (props && props.sobre_falla) return '#c62828';
      const d = props && props.distancia_falla;
      if (d == null) return '#757575';
      if (d < 10) return '#c62828';
      if (d < 30) return '#e65100';
      if (d < 50) return '#ef6c00';
      return '#2e7d32';
    }

    function pointToLayer(f, latlng) {
      const c = colorVivienda(f.properties);
      return L.circleMarker(latlng, {
        radius: 8,
        fillColor: c,
        color: '#333',
        weight: 1,
        fillOpacity: 0.9
      });
    }

    function onEachVivienda(f, layer) {
      const p = f.properties || {};
      const txt = [p.nombre_propietario, p.direccion, p.colonia, 'Distancia falla: ' + (p.distancia_falla != null ? p.distancia_falla.toFixed(0) + ' m' : 'N/A')].filter(Boolean).join(' — ');
      layer.bindPopup(txt);
    }

    Promise.all([
      fetch(fallasUrl).then(r => r.json()),
      fetch(viviendasUrl).then(r => r.json())
    ]).then(([fallas, viviendas]) => {
      if (fallas.features && fallas.features.length) {
        L.geoJSON(fallas, {
          style: { color: '#c62828', weight: 3 }
        }).addTo(map);
      }
      if (viviendas.features && viviendas.features.length) {
        L.geoJSON(viviendas, {
          pointToLayer: pointToLayer,
          onEachFeature: onEachVivienda
        }).addTo(map);
        const bounds = L.geoJSON(viviendas).getBounds();
        if (bounds.isValid()) map.fitBounds(bounds, { padding: [40, 40] });
      }
      document.getElementById('cargando').style.display = 'none';
      document.getElementById('leyenda').style.display = 'block';
    }).catch(err => {
      document.getElementById('cargando').textContent = 'Error al cargar datos: ' + err.message;
    });
  </script>
</body>
</html>"""


def get_mapa_html() -> str:
    """Devuelve el HTML de la página del mapa (para servir desde main en /mapa)."""
    return _get_mapa_html()
