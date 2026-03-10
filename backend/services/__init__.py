from .vivienda import (
    crear_vivienda,
    listar_viviendas,
    obtener_vivienda,
    actualizar_vivienda,
    eliminar_vivienda,
    listar_sobre_falla,
)

from .falla import (
    listar_fallas,
    crear_falla,
    obtener_falla,
    fallas_con_geometria_geojson,  # <--- Agregada
    fallas_buffers,
    importar_geojson,
)