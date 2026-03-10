"""
Cálculo del Índice de Riesgo de Vivienda (IRV).

IRV = (0.4 * severidad_dano) + (0.3 * proximidad_falla) + (0.2 * tipo_construccion) + (0.1 * habitantes)

Clasificación:
- 0-1: bajo
- 1-2: medio
- 2-3: alto
- 3+: crítico
"""
from typing import Optional


# Puntos por nivel de daño (0-4 escala para fórmula)
NIVEL_DANO_PUNTOS = {
    None: 0,
    "": 0,
    "leve": 0.5,
    "moderado": 1.5,
    "severo": 2.5,
    "inhabitable": 4.0,
}

# Tipo construcción: mayor = más vulnerable (0-4)
TIPO_CONSTRUCCION_PUNTOS = {
    None: 1,
    "": 1,
    "adobe": 4,
    "bahareque": 3.5,
    "madera": 2.5,
    "mamposteria": 2,
    "concreto": 1,
    "acero": 0.5,
}


def _normalizar(val: float, min_val: float, max_val: float) -> float:
    """Normalizar valor a escala 0-4."""
    if max_val <= min_val:
        return 0
    r = max(0, min(4, (val - min_val) / (max_val - min_val) * 4))
    return round(r, 2)


def calcular_proximidad_puntos(distancia_metros: Optional[float]) -> float:
    """
    Proximidad a falla: 0m -> 4, 50m -> 2, 100m+ -> 0.
    Escala 0-4.
    """
    if distancia_metros is None or distancia_metros < 0:
        return 2.0  # valor medio si no hay dato
    if distancia_metros <= 5:
        return 4.0
    if distancia_metros <= 20:
        return 3.0
    if distancia_metros <= 50:
        return 2.0
    if distancia_metros <= 100:
        return 1.0
    return 0.5


def calcular_habitantes_puntos(habitantes: int) -> float:
    """Habitantes: normalizar a 0-4 (ej: 0->0, 6+->4)."""
    return _normalizar(float(habitantes), 0, 8)


def calcular_indice_riesgo_vivienda(
    nivel_dano: Optional[str],
    distancia_falla_metros: Optional[float],
    tipo_construccion: Optional[str],
    habitantes_total: int,
) -> float:
    """
    IRV = 0.4*severidad + 0.3*proximidad + 0.2*tipo_construccion + 0.1*habitantes
    Cada componente en escala 0-4.
    """
    severidad = NIVEL_DANO_PUNTOS.get(nivel_dano, NIVEL_DANO_PUNTOS.get(""))
    proximidad = calcular_proximidad_puntos(distancia_falla_metros)
    tipo_pts = TIPO_CONSTRUCCION_PUNTOS.get(
        (tipo_construccion or "").strip().lower(),
        TIPO_CONSTRUCCION_PUNTOS.get(None),
    )
    hab_pts = calcular_habitantes_puntos(habitantes_total or 0)

    irv = 0.4 * severidad + 0.3 * proximidad + 0.2 * tipo_pts + 0.1 * hab_pts
    return round(irv, 2)


def clasificar_riesgo(irv: float) -> str:
    if irv < 1:
        return "bajo"
    if irv < 2:
        return "medio"
    if irv < 3:
        return "alto"
    return "critico"
