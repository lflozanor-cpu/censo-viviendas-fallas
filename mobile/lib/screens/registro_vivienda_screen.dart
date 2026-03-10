import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/vivienda_model.dart';
import '../models/foto_model.dart';
import '../services/api_service.dart';
import '../services/gps_service.dart';
import '../theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RegistroViviendaScreen extends StatefulWidget {
  const RegistroViviendaScreen({super.key, this.viviendaToEdit});

  final ViviendaModel? viviendaToEdit;

  @override
  State<RegistroViviendaScreen> createState() => _RegistroViviendaScreenState();
}

class _RegistroViviendaScreenState extends State<RegistroViviendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _localidadController = TextEditingController();
  final _anioController = TextEditingController();
  final _observacionesController = TextEditingController();
  int _habitantes = 0, _ninos = 0, _adultosMayores = 0, _discapacidad = 0;
  String? _tipoConstruccion;
  int _niveles = 1;
  int? _anioConstruccion;
  bool _grietasMuros = false, _grietasPiso = false, _separacionMuroTecho = false;
  bool _hundimiento = false, _inclinacion = false, _fracturaReciente = false;
  String? _nivelDano;
  double? _lat, _lon, _altitud, _precisionGps;
  final List<FotoModel> _fotos = [];
  bool _loadingGps = false;
  bool _saving = false;

  bool get _isEditing => widget.viviendaToEdit != null;

  void _cargarDesdeVivienda(ViviendaModel v) {
    _nombreController.text = v.nombrePropietario ?? '';
    _telefonoController.text = v.telefono ?? '';
    _direccionController.text = v.direccion ?? '';
    _coloniaController.text = v.colonia ?? '';
    _localidadController.text = v.localidad ?? '';
    _anioController.text = v.anioConstruccion?.toString() ?? '';
    _observacionesController.text = v.observaciones ?? '';
    _habitantes = v.habitantesTotal;
    _ninos = v.ninos;
    _adultosMayores = v.adultosMayores;
    _discapacidad = v.personasDiscapacidad;
    _tipoConstruccion = v.tipoConstruccion;
    _niveles = v.niveles;
    _anioConstruccion = v.anioConstruccion;
    _grietasMuros = v.grietasMuros;
    _grietasPiso = v.grietasPiso;
    _separacionMuroTecho = v.separacionMuroTecho;
    _hundimiento = v.hundimiento;
    _inclinacion = v.inclinacion;
    _fracturaReciente = v.fracturaReciente;
    _nivelDano = v.nivelDano;
    _lat = v.lat;
    _lon = v.lon;
    _altitud = v.altitud;
    _precisionGps = v.precisionGps;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) _cargarDesdeVivienda(widget.viviendaToEdit!);
    if (!_isEditing) _capturarGps();
  }

  Future<void> _capturarGps() async {
    setState(() => _loadingGps = true);
    final loc = await GpsService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _lat = loc.latitude;
        _lon = loc.longitude;
        _altitud = loc.altitude;
        _precisionGps = loc.accuracy;
        _loadingGps = false;
      });
    } else {
      setState(() => _loadingGps = false);
    }
  }

  Future<void> _tomarFoto(String tipo) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final name = '${DateTime.now().millisecondsSinceEpoch}_$tipo.jpg';
    final path = p.join(dir.path, name);
    await File(file.path).copy(path);
    final loc = await GpsService.getCurrentLocation();
    setState(() {
      _fotos.add(FotoModel(
        viviendaId: '',
        tipoFoto: tipo,
        url: path,
        fecha: DateTime.now(),
        lat: loc?.latitude,
        lon: loc?.longitude,
      ));
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture la ubicación GPS antes de guardar')),
      );
      return;
    }
    final anio = int.tryParse(_anioController.text.trim());
    setState(() => _saving = true);
    final v = ViviendaModel(
      id: widget.viviendaToEdit?.id,
      nombrePropietario: _nombreController.text.trim().isEmpty ? null : _nombreController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      colonia: _coloniaController.text.trim().isEmpty ? null : _coloniaController.text.trim(),
      localidad: _localidadController.text.trim().isEmpty ? null : _localidadController.text.trim(),
      habitantesTotal: _habitantes,
      ninos: _ninos,
      adultosMayores: _adultosMayores,
      personasDiscapacidad: _discapacidad,
      tipoConstruccion: _tipoConstruccion,
      niveles: _niveles,
      anioConstruccion: anio,
      grietasMuros: _grietasMuros,
      grietasPiso: _grietasPiso,
      separacionMuroTecho: _separacionMuroTecho,
      hundimiento: _hundimiento,
      inclinacion: _inclinacion,
      fracturaReciente: _fracturaReciente,
      nivelDano: _nivelDano,
      observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
      lat: _lat,
      lon: _lon,
      altitud: _altitud,
      precisionGps: _precisionGps,
    );
    final api = context.read<ApiService>();
    if (_isEditing && widget.viviendaToEdit!.id != null) {
      final actualizada = await api.updateVivienda(widget.viviendaToEdit!.id!, v);
      setState(() => _saving = false);
      if (!mounted) return;
      if (actualizada != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vivienda actualizada')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
      }
      return;
    }
    final creada = await api.createVivienda(v);
    setState(() => _saving = false);
    if (!mounted) return;
    if (creada != null && creada.id != null) {
      for (final f in _fotos) {
        await api.addFoto(creada.id!, f.tipoFoto, f.url, lat: f.lat, lon: f.lon);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vivienda registrada')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar. ¿Modo offline? Se guardará al sincronizar.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _coloniaController.dispose();
    _localidadController.dispose();
    _anioController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Widget _counterRow(String label, int value, VoidCallback onMinus, VoidCallback onPlus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.secondary))),
          IconButton.filled(icon: const Icon(Icons.remove, size: 20), onPressed: onMinus, style: IconButton.styleFrom(backgroundColor: AppTheme.primary.withOpacity(0.12), foregroundColor: AppTheme.primary)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          IconButton.filled(icon: const Icon(Icons.add, size: 20), onPressed: onPlus, style: IconButton.styleFrom(backgroundColor: AppTheme.primary.withOpacity(0.12), foregroundColor: AppTheme.primary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar vivienda' : 'Registrar vivienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Datos generales
            AppTheme.sectionTitle('Datos generales', icon: Icons.person_outline),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                children: [
                  TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Propietario')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextFormField(controller: _direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _coloniaController, decoration: const InputDecoration(labelText: 'Colonia')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _localidadController, decoration: const InputDecoration(labelText: 'Localidad')),
                ],
              ),
            ),
            AppTheme.sectionTitle('Datos sociales', icon: Icons.people_outline),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                children: [
                  _counterRow('Habitantes', _habitantes, () => setState(() => _habitantes = (_habitantes - 1).clamp(0, 99)), () => setState(() => _habitantes++)),
                  _counterRow('Niños', _ninos, () => setState(() => _ninos = (_ninos - 1).clamp(0, 99)), () => setState(() => _ninos++)),
                  _counterRow('Adultos mayores', _adultosMayores, () => setState(() => _adultosMayores = (_adultosMayores - 1).clamp(0, 99)), () => setState(() => _adultosMayores++)),
                  _counterRow('Discapacidad', _discapacidad, () => setState(() => _discapacidad = (_discapacidad - 1).clamp(0, 99)), () => setState(() => _discapacidad++)),
                ],
              ),
            ),
            AppTheme.sectionTitle('Estructural', icon: Icons.apartment),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _tipoConstruccion,
                    decoration: const InputDecoration(labelText: 'Tipo construcción'),
                    items: ['adobe', 'bahareque', 'madera', 'mamposteria', 'concreto', 'acero'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _tipoConstruccion = v),
                  ),
                  const SizedBox(height: 12),
                  _counterRow('Niveles', _niveles, () => setState(() => _niveles = (_niveles - 1).clamp(1, 10)), () => setState(() => _niveles++)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _anioController, decoration: const InputDecoration(labelText: 'Año construcción'), keyboardType: TextInputType.number),
                ],
              ),
            ),
            AppTheme.sectionTitle('Daños estructurales', icon: Icons.warning_amber_rounded),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(title: const Text('Grietas en muros'), value: _grietasMuros, onChanged: (v) => setState(() => _grietasMuros = v ?? false), contentPadding: EdgeInsets.zero),
                  CheckboxListTile(title: const Text('Grietas en piso'), value: _grietasPiso, onChanged: (v) => setState(() => _grietasPiso = v ?? false), contentPadding: EdgeInsets.zero),
                  CheckboxListTile(title: const Text('Separación muro-techo'), value: _separacionMuroTecho, onChanged: (v) => setState(() => _separacionMuroTecho = v ?? false), contentPadding: EdgeInsets.zero),
                  CheckboxListTile(title: const Text('Hundimiento'), value: _hundimiento, onChanged: (v) => setState(() => _hundimiento = v ?? false), contentPadding: EdgeInsets.zero),
                  CheckboxListTile(title: const Text('Inclinación'), value: _inclinacion, onChanged: (v) => setState(() => _inclinacion = v ?? false), contentPadding: EdgeInsets.zero),
                  CheckboxListTile(title: const Text('Fractura reciente'), value: _fracturaReciente, onChanged: (v) => setState(() => _fracturaReciente = v ?? false), contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _nivelDano,
                    decoration: const InputDecoration(labelText: 'Nivel de daño'),
                    items: ['leve', 'moderado', 'severo', 'inhabitable'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _nivelDano = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _observacionesController, decoration: const InputDecoration(labelText: 'Observaciones'), maxLines: 2),
                ],
              ),
            ),
            AppTheme.sectionTitle('Ubicación GPS', icon: Icons.gps_fixed),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loadingGps) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())) else Text('Lat: $_lat  Lon: $_lon  Precisión: $_precisionGps m', style: const TextStyle(fontSize: 13, color: AppTheme.secondary)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _capturarGps, icon: const Icon(Icons.gps_fixed, size: 20), label: const Text('Actualizar ubicación')),
                ],
              ),
            ),
            AppTheme.sectionTitle('Fotografías', icon: Icons.photo_camera_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sectionCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(onPressed: () => _tomarFoto('fachada'), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Fachada')),
                      FilledButton.tonalIcon(onPressed: () => _tomarFoto('grietas'), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Grietas')),
                      FilledButton.tonalIcon(onPressed: () => _tomarFoto('interior'), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Interior')),
                      FilledButton.tonalIcon(onPressed: () => _tomarFoto('terreno'), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Terreno')),
                    ],
                  ),
                  if (_fotos.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${_fotos.length} foto(s)', style: const TextStyle(fontSize: 13, color: AppTheme.secondary))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _guardar,
              child: _saving ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar vivienda'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
