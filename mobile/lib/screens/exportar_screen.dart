import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ExportarScreen extends StatelessWidget {
  const ExportarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTheme.sectionTitle('Formatos de exportación', icon: Icons.file_download_outlined),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Descargue los datos desde el panel web o desde la API del servidor.',
              style: TextStyle(fontSize: 14, color: AppTheme.secondary),
            ),
          ),
          _ExportTile(
            title: 'Excel',
            subtitle: '/api/export/excel',
            icon: Icons.table_chart_rounded,
          ),
          _ExportTile(
            title: 'GeoJSON',
            subtitle: '/api/export/geojson',
            icon: Icons.map_rounded,
          ),
          _ExportTile(
            title: 'KMZ',
            subtitle: '/api/export/kmz',
            icon: Icons.place_rounded,
          ),
          _ExportTile(
            title: 'Viviendas sobre falla',
            subtitle: '/api/export/viviendas_sobre_falla',
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ExportTile({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.sectionCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace')),
        ),
      ),
    );
  }
}
