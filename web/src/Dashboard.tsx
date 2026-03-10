import { useState, useEffect } from 'react'
import axios from 'axios'
import { API_BASE, getToken } from './App'
import MapView from './MapView'
import TablaViviendas from './TablaViviendas'

export interface Vivienda {
  id: string
  nombre_propietario: string | null
  direccion: string | null
  nivel_dano: string | null
  sobre_falla: boolean
  distancia_falla: number | null
  lat: number | null
  lon: number | null
  indice_riesgo_vivienda: number | null
  [key: string]: unknown
}

interface Stats {
  total_viviendas: number
  viviendas_sobre_falla: number
  viviendas_dano_severo: number
  poblacion_afectada: number
}

interface DashboardProps {
  token: string
  onLogout: () => void
}

const auth = () => ({ headers: { Authorization: `Bearer ${getToken()}` } })

export default function Dashboard({ token, onLogout }: DashboardProps) {
  const [viviendas, setViviendas] = useState<Vivienda[]>([])
  const [stats, setStats] = useState<Stats | null>(null)
  const [filterDano, setFilterDano] = useState<string>('')
  const [filterSobreFalla, setFilterSobreFalla] = useState<boolean | ''>('')
  const [tab, setTab] = useState<'mapa' | 'tabla'>('mapa')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      try {
        const [vRes, sRes] = await Promise.all([
          axios.get(API_BASE + '/viviendas', { ...auth(), params: { limit: 2000 } }),
          axios.get(API_BASE + '/estadisticas', auth()),
        ])
        setViviendas(vRes.data)
        setStats(sRes.data)
      } catch (e) {
        console.error(e)
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [token])

  const filtered = viviendas.filter(v => {
    if (filterDano && v.nivel_dano !== filterDano) return false
    if (filterSobreFalla !== '' && v.sobre_falla !== filterSobreFalla) return false
    return true
  })

  const downloadExport = async (path: string, filename: string) => {
    try {
      const res = await fetch(API_BASE + path, { headers: { Authorization: `Bearer ${getToken()}` } })
      const blob = await res.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      a.click()
      URL.revokeObjectURL(url)
    } catch (e) {
      console.error(e)
      alert('Error al descargar')
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <header style={{ padding: '12px 24px', borderBottom: '1px solid #ddd', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1 style={{ margin: 0 }}>Censo Viviendas Fallas - Admin</h1>
        <div>
          <button onClick={() => setTab('mapa')} style={{ marginRight: 8 }}>Mapa</button>
          <button onClick={() => setTab('tabla')} style={{ marginRight: 8 }}>Tabla</button>
          <button onClick={() => downloadExport('/export/excel', 'viviendas.xlsx')} style={{ marginRight: 8 }}>Exportar Excel</button>
          <button onClick={() => downloadExport('/export/kmz', 'viviendas.kmz')} style={{ marginRight: 8 }}>KMZ</button>
          <button onClick={() => { downloadExport('/export/geojson', 'viviendas.geojson') }} style={{ marginRight: 8 }}>GeoJSON</button>
          <button onClick={onLogout}>Salir</button>
        </div>
      </header>

      <div style={{ padding: 16, borderBottom: '1px solid #eee', display: 'flex', gap: 16, flexWrap: 'wrap' }}>
        <label>
          Nivel daño:
          <select value={filterDano} onChange={e => setFilterDano(e.target.value)} style={{ marginLeft: 8 }}>
            <option value="">Todos</option>
            <option value="leve">Leve</option>
            <option value="moderado">Moderado</option>
            <option value="severo">Severo</option>
            <option value="inhabitable">Inhabitable</option>
          </select>
        </label>
        <label>
          Sobre falla:
          <select value={String(filterSobreFalla)} onChange={e => setFilterSobreFalla(e.target.value === '' ? '' : e.target.value === 'true')} style={{ marginLeft: 8 }}>
            <option value="">Todos</option>
            <option value="true">Sí</option>
            <option value="false">No</option>
          </select>
        </label>
        {stats && (
          <span style={{ marginLeft: 'auto', color: '#666' }}>
            Total: {stats.total_viviendas} · Sobre falla: {stats.viviendas_sobre_falla} · Daño severo: {stats.viviendas_dano_severo} · Población: {stats.poblacion_afectada}
          </span>
        )}
      </div>

      <main style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        {loading ? (
          <div style={{ padding: 48, textAlign: 'center' }}>Cargando...</div>
        ) : tab === 'mapa' ? (
          <MapView viviendas={filtered} />
        ) : (
          <TablaViviendas viviendas={filtered} />
        )}
      </main>
    </div>
  )
}
