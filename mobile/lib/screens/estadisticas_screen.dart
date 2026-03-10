import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = context.read<ApiService>();
    final data = await api.getEstadisticas();
    if (mounted) setState(() { _stats = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudieron cargar estadísticas', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppTheme.sectionTitle('Resumen del censo', icon: Icons.analytics_outlined),
                    _StatCard(
                      title: 'Total viviendas',
                      value: _stats!['total_viviendas']?.toString() ?? '0',
                      icon: Icons.home_rounded,
                      color: AppTheme.primary,
                    ),
                    _StatCard(
                      title: 'Viviendas sobre falla',
                      value: _stats!['viviendas_sobre_falla']?.toString() ?? '0',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                    ),
                    _StatCard(
                      title: 'Viviendas con daño severo',
                      value: _stats!['viviendas_dano_severo']?.toString() ?? '0',
                      icon: Icons.build_circle_outlined,
                      color: Colors.orange.shade700,
                    ),
                    _StatCard(
                      title: 'Población afectada',
                      value: _stats!['poblacion_afectada']?.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sectionCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.secondary)),
          ),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
