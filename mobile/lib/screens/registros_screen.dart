import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/vivienda_model.dart';
import '../theme/app_theme.dart';
import 'registro_vivienda_screen.dart';

/// Niveles de afectación según distancia a la falla (metros).
/// Coincide con backend: buffer 10 m = sobre falla.
String nivelAfectacionTexto(ViviendaModel v) {
  if (v.sobreFalla) return 'Crítica (sobre falla)';
  final d = v.distanciaFalla;
  if (d == null) return 'Sin datos';
  if (d < 10) return 'Crítica';
  if (d < 30) return 'Alta';
  if (d < 50) return 'Media';
  return 'Baja';
}

Color nivelAfectacionColor(ViviendaModel v) {
  if (v.sobreFalla) return Colors.red;
  final d = v.distanciaFalla;
  if (d == null) return Colors.grey;
  if (d < 10) return Colors.red;
  if (d < 30) return Colors.deepOrange;
  if (d < 50) return Colors.orange;
  return Colors.green;
}

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  List<ViviendaModel> _viviendas = [];
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final api = context.read<ApiService>();
    final list = await api.getViviendas();
    if (mounted) setState(() { _viviendas = list; _loading = false; });
  }

  Future<void> _descargarExcel() async {
    setState(() => _downloading = true);
    final api = context.read<ApiService>();
    final bytes = await api.getExportExcelBytes();
    if (!mounted) return;
    setState(() => _downloading = false);
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo descargar el archivo')),
      );
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/viviendas_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Exportación Censo Viviendas');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  void _editar(ViviendaModel v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroViviendaScreen(viviendaToEdit: v),
      ),
    ).then((_) => _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros'),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            onPressed: _downloading ? null : _descargarExcel,
            tooltip: 'Descargar Excel',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _viviendas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No hay viviendas registradas', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text('Use "Registrar vivienda" para agregar el primer registro.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _viviendas.length,
                    itemBuilder: (context, i) {
                      final v = _viviendas[i];
                      final nivel = nivelAfectacionTexto(v);
                      final colorNivel = nivelAfectacionColor(v);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: AppTheme.sectionCardDecoration(),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorNivel,
                            child: Icon(Icons.home, color: Colors.white, size: 22),
                          ),
                          title: Text(
                            v.nombrePropietario ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v.direccion != null && v.direccion!.isNotEmpty)
                                Text(v.direccion!, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorNivel.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      nivel,
                                      style: TextStyle(fontSize: 12, color: colorNivel, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (v.distanciaFalla != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${v.distanciaFalla!.toStringAsFixed(0)} m',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                  if (v.nivelDano != null && v.nivelDano!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text('· ${v.nivelDano}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editar(v),
                            tooltip: 'Editar',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
