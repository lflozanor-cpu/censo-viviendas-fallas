import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../services/gps_service.dart';
import '../models/vivienda_model.dart';
import '../theme/app_theme.dart';
import 'registros_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapController = MapController();
  List<ViviendaModel> _viviendas = [];
  List<Polyline> _fallasPolylines = [];
  bool _loading = true;
  LatLng _center = const LatLng(19.4326, -99.1332);
  double _zoom = 10.0;

  bool _measuring = false;
  final List<LatLng> _measurePoints = [];
  static final _distance = Distance();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<Polyline> _geojsonToPolylines(Map<String, dynamic> geojson) {
    final features = geojson['features'] as List<dynamic>? ?? [];
    final polylines = <Polyline>[];
    for (final f in features) {
      final geom = f['geometry'] as Map<String, dynamic>?;
      if (geom == null || geom['type'] != 'LineString') continue;
      final coords = geom['coordinates'] as List<dynamic>? ?? [];
      if (coords.isEmpty) continue;
      final points = coords.map<LatLng>((c) {
        final list = c as List;
        return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
      }).toList();
      polylines.add(Polyline(
        points: points,
        color: Colors.red,
        strokeWidth: 4,
      ));
    }
    return polylines;
  }

  Future<void> _cargar() async {
    final api = context.read<ApiService>();
    final results = await Future.wait([
      api.getViviendas(),
      api.getFallasGeoJson(),
    ]);
    final viviendas = results[0] as List<ViviendaModel>;
    final fallasGeo = results[1] as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _viviendas = viviendas;
      _fallasPolylines = _geojsonToPolylines(fallasGeo);
      _loading = false;
    });
    _irAMiUbicacion();
  }

  Future<void> _irAMiUbicacion() async {
    final pos = await GpsService.getCurrentLocation();
    if (!mounted || pos == null) return;
    final center = LatLng(pos.latitude, pos.longitude);
    const zoomCalle = 17.0;
    setState(() {
      _center = center;
      _zoom = zoomCalle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(center, zoomCalle);
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_measuring) return;
    setState(() {
      if (_measurePoints.length >= 2) _measurePoints.clear();
      _measurePoints.add(point);
    });
  }

  void _toggleMedir() {
    setState(() {
      _measuring = !_measuring;
      if (!_measuring) _measurePoints.clear();
    });
  }

  double? _getMeasureDistanceM() {
    if (_measurePoints.length != 2) return null;
    return _distance(_measurePoints[0], _measurePoints[1]).toDouble();
  }

  void _showViviendaAtributos(ViviendaModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.home, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      v.nombrePropietario ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _AtributoRow(icon: Icons.place, label: 'Dirección', value: v.direccion ?? '—'),
              _AtributoRow(icon: Icons.location_city, label: 'Colonia', value: v.colonia ?? '—'),
              _AtributoRow(icon: Icons.phone, label: 'Teléfono', value: v.telefono ?? '—'),
              _AtributoRow(icon: Icons.warning_amber, label: 'Nivel de afectación', value: nivelAfectacionTexto(v), valueColor: nivelAfectacionColor(v)),
              if (v.distanciaFalla != null)
                _AtributoRow(icon: Icons.straighten, label: 'Distancia a falla', value: '${v.distanciaFalla!.toStringAsFixed(1)} m'),
              _AtributoRow(icon: Icons.build, label: 'Nivel de daño', value: v.nivelDano ?? '—'),
              _AtributoRow(icon: Icons.people, label: 'Habitantes', value: '${v.habitantesTotal}'),
              _AtributoRow(icon: Icons.category, label: 'Tipo construcción', value: v.tipoConstruccion ?? '—'),
              if (v.observaciones != null && v.observaciones!.isNotEmpty)
                _AtributoRow(icon: Icons.notes, label: 'Observaciones', value: v.observaciones!),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measureLine = _measurePoints.length == 2
        ? PolylineLayer(
            polylines: [
              Polyline(points: _measurePoints, color: AppTheme.primary, strokeWidth: 3),
            ],
          )
        : null;
    final measureDistance = _getMeasureDistanceM();
    final measureMarkers = _measurePoints.isEmpty
        ? null
        : MarkerLayer(
            markers: _measurePoints.asMap().entries.map((e) {
              return Marker(
                point: e.value,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              );
            }).toList(),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: Icon(_measuring ? Icons.straighten : Icons.straighten, color: _measuring ? Colors.amber : null),
            onPressed: _toggleMedir,
            tooltip: _measuring ? 'Salir de medir' : 'Medir distancia',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                    onTap: _onMapTap,
                    interactionOptions: InteractionOptions(flags: _measuring ? InteractiveFlag.all : InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.censo_viviendas_fallas',
                    ),
                    PolylineLayer(polylines: _fallasPolylines),
                    if (measureLine != null) measureLine,
                    MarkerLayer(
                      markers: _viviendas.where((v) => v.lat != null && v.lon != null).map((v) {
                        Color color = Colors.green;
                        if (v.sobreFalla) color = Colors.red;
                        else if ((v.distanciaFalla ?? 999) < 50) color = Colors.orange;
                        return Marker(
                          point: LatLng(v.lat!, v.lon!),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => _showViviendaAtributos(v),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (measureMarkers != null) measureMarkers,
                  ],
                ),
                if (_measuring && _measurePoints.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          _measurePoints.length == 1
                              ? 'Toque otro punto en el mapa para medir'
                              : 'Distancia: ${measureDistance! >= 1000 ? '${(measureDistance / 1000).toStringAsFixed(2)} km' : '${measureDistance.toStringAsFixed(0)} m'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 180,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'location',
                        onPressed: _loading ? null : _irAMiUbicacion,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildLeyenda(),
    );
  }

  Widget _buildLeyenda() {
    final conCoords = _viviendas.where((v) => v.lat != null && v.lon != null).length;
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 24, height: 5, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Fallas geológicas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Viviendas (toque para ver datos):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _leyendaColor(Colors.green, 'Lejos'),
                  _leyendaColor(Colors.orange, '<50 m'),
                  _leyendaColor(Colors.red, 'Sobre falla'),
                ],
              ),
              if (conCoords == 0) ...[
                const SizedBox(height: 6),
                Text('No hay viviendas con ubicación.', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ] else ...[
                const SizedBox(height: 4),
                Text('$conCoords vivienda(s)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _leyendaColor(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _AtributoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AtributoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
