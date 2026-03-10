import type { Vivienda } from './Dashboard'

interface TablaViviendasProps {
  viviendas: Vivienda[]
}

export default function TablaViviendas({ viviendas }: TablaViviendasProps) {
  return (
    <div style={{ overflow: 'auto', flex: 1, padding: 16 }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #ddd' }}>
            <th style={{ textAlign: 'left', padding: 8 }}>Propietario</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Dirección</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Nivel daño</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Distancia falla (m)</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Sobre falla</th>
            <th style={{ textAlign: 'left', padding: 8 }}>IRV</th>
          </tr>
        </thead>
        <tbody>
          {viviendas.map(v => (
            <tr key={v.id} style={{ borderBottom: '1px solid #eee' }}>
              <td style={{ padding: 8 }}>{v.nombre_propietario ?? '-'}</td>
              <td style={{ padding: 8 }}>{v.direccion ?? '-'}</td>
              <td style={{ padding: 8 }}>{v.nivel_dano ?? '-'}</td>
              <td style={{ padding: 8 }}>{v.distancia_falla != null ? v.distancia_falla.toFixed(1) : '-'}</td>
              <td style={{ padding: 8 }}>{v.sobre_falla ? 'Sí' : 'No'}</td>
              <td style={{ padding: 8 }}>{v.indice_riesgo_vivienda != null ? v.indice_riesgo_vivienda.toFixed(2) : '-'}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {viviendas.length === 0 && (
        <p style={{ textAlign: 'center', color: '#666', padding: 24 }}>No hay registros con los filtros aplicados.</p>
      )}
    </div>
  )
}
