"""
Importa fallas geológicas desde un archivo GeoJSON a la base de datos.
Uso (desde la raíz del backend):
  python -m scripts.import_fallas_geojson
  python -m scripts.import_fallas_geojson "C:\\datos\\fallas.geojson"
"""
import json
import sys
from pathlib import Path

# Añadir el directorio padre al path para importar database y services
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from database import SessionLocal
from services.falla import importar_geojson


def main():
    if len(sys.argv) > 1:
        ruta = Path(sys.argv[1])
    else:
        ruta = Path(r"C:\datos\fallas.geojson")

    if not ruta.exists():
        print(f"Error: no se encuentra el archivo: {ruta}")
        print("Uso: python -m scripts.import_fallas_geojson [ruta_al_archivo.geojson]")
        sys.exit(1)

    print(f"Leyendo {ruta}...")
    with open(ruta, encoding="utf-8") as f:
        geojson_data = json.load(f)

    db = SessionLocal()
    try:
        result = importar_geojson(db, geojson_data)
        count = result.get("imported_count", 0)
        print(f"Importadas {count} fallas correctamente.")
    except Exception as e:
        print(f"Error al importar: {e}")
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
