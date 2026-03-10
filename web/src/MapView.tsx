import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import L from 'leaflet'
import type { Vivienda } from './Dashboard'

const redIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})

const orangeIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})

const greenIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})

function iconFor(v: Vivienda) {
  if (v.sobre_falla) return redIcon
  if ((v.distancia_falla ?? 999) < 50) return orangeIcon
  return greenIcon
}

function FitBounds({ viviendas }: { viviendas: Vivienda[] }) {
  const map = useMap()
  const withCoords = viviendas.filter(v => v.lat != null && v.lon != null)
  if (withCoords.length === 0) return null
  const bounds = L.latLngBounds(withCoords.map(v => [v.lat!, v.lon!]))
  map.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 })
  return null
}

interface MapViewProps {
  viviendas: Vivienda[]
}

export default function MapView({ viviendas }: MapViewProps) {
  const withCoords = viviendas.filter(v => v.lat != null && v.lon != null)
  const center: [number, number] = withCoords.length
    ? [withCoords.reduce((a, v) => a + (v.lat ?? 0), 0) / withCoords.length, withCoords.reduce((a, v) => a + (v.lon ?? 0), 0) / withCoords.length]
    : [19.43, -99.13]

  return (
    <div style={{ height: '100%', minHeight: 400 }}>
      <MapContainer center={center} zoom={12} style={{ height: '100%', width: '100%' }}>
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        {withCoords.length > 0 && <FitBounds viviendas={viviendas} />}
        {withCoords.map(v => (
          <Marker key={v.id} position={[v.lat!, v.lon!]} icon={iconFor(v)}>
            <Popup>
              <strong>{v.nombre_propietario ?? 'Sin nombre'}</strong><br />
              {v.direccion}<br />
              Daño: {v.nivel_dano ?? '-'} · Distancia falla: {v.distancia_falla != null ? `${v.distancia_falla.toFixed(0)} m` : '-'}<br />
              {v.sobre_falla && <span style={{ color: 'red' }}>Sobre falla</span>}
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  )
}
