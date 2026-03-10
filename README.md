# Sistema de Censo de Viviendas sobre Fallas Geológicas

Sistema para censar viviendas ubicadas sobre fallas geológicas: registro casa por casa, datos estructurales y sociales, fotos georreferenciadas y análisis espacial (detección sobre falla, distancia, índice de riesgo).

## Componentes

- **Backend** (Python, FastAPI, PostgreSQL/PostGIS): API REST, análisis espacial, importación GeoJSON de fallas, exportación Excel/GeoJSON/KMZ.
- **App móvil** (Flutter): registro en campo, GPS, fotos, mapa, estadísticas, sincronización.
- **Panel web** (React, Leaflet): mapa de viviendas, filtros por daño y distancia a falla, tabla, exportación.

## Requisitos

- Python 3.11+
- PostgreSQL con extensión PostGIS
- Node 18+ (panel web)
- Flutter 3.x (app móvil)

## Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

Crear base de datos y tablas:

```bash
# En PostgreSQL: CREATE DATABASE censo_fallas;
# Luego:
python scripts/init_db.py
```

Variables de entorno (opcional, ver `.env.example`):

- `DATABASE_URL`: conexión PostgreSQL (por defecto `postgresql://postgres:postgres@localhost:5432/censo_fallas`)
- `SECRET_KEY`: clave JWT

Crear usuario inicial (inspector):

```python
# En Python con el entorno activado:
from database import SessionLocal
from models import User
from utils.auth import get_password_hash
db = SessionLocal()
u = User(email="inspector@test.com", hashed_password=get_password_hash("password"), full_name="Inspector")
db.add(u)
db.commit()
```

Iniciar API:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Documentación: http://localhost:8000/docs

### Endpoints principales

- **Auth**: `POST /api/auth/register`, `POST /api/auth/login`
- **Viviendas**: `POST/GET/PUT/DELETE /api/viviendas`, `GET /api/viviendas/sobre_falla` (GeoJSON)
- **Fallas**: `GET /api/fallas`, `GET /api/fallas/buffer`, `POST /api/fallas/upload_geojson`
- **Estadísticas**: `GET /api/estadisticas`
- **Exportación**: `GET /api/export/excel`, `/export/geojson`, `/export/kmz`, `/export/viviendas_sobre_falla`

## App móvil (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

En `lib/services/api_service.dart` ajuste `baseUrl` si el backend no está en la misma máquina (por ejemplo `http://IP:8000/api` para dispositivo físico).

## Panel web

```bash
cd web
npm install
npm run dev
```

Abrir http://localhost:3000. Iniciar sesión con el usuario creado en el backend.

## Análisis espacial

- **Sobre falla**: se considera que una vivienda está sobre la falla si su punto intersecta un buffer de 5 m sobre la geometría de la falla (`ST_Intersects` con `ST_Buffer(geom::geography, 5)`).
- **Distancia a falla**: `ST_Distance(vivienda.geom::geography, falla.geom::geography)` en metros; se guarda la distancia mínima a cualquier falla.
- **Índice de riesgo (IRV)**:  
  `IRV = 0.4*severidad_daño + 0.3*proximidad_falla + 0.2*tipo_construcción + 0.1*habitantes`  
  Clasificación: 0–1 bajo, 1–2 medio, 2–3 alto, 3+ crítico.

## Estructura del proyecto

```
censo-viviendas-fallas/
├── backend/          # FastAPI, PostGIS, JWT, exportación
├── mobile/           # Flutter: formulario, GPS, fotos, mapa, offline
├── web/              # React + Leaflet: dashboard, filtros, exportación
└── README.md
```
