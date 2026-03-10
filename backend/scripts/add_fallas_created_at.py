"""
Añade la columna created_at a fallas_geologicas si no existe.
Uso: python -m scripts.add_fallas_created_at
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import text
from database import engine


def main():
    with engine.connect() as conn:
        conn.execute(text("""
            ALTER TABLE fallas_geologicas
            ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT now()
        """))
        conn.commit()
    print("Columna created_at añadida (o ya existía).")


if __name__ == "__main__":
    main()
