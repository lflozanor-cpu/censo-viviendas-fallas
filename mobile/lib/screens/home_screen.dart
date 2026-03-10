import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'registro_vivienda_screen.dart';
import 'mapa_screen.dart';
import 'registros_screen.dart';
import 'estadisticas_screen.dart';
import 'exportar_screen.dart';
import 'configuracion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthService>().loadStored();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Censo Viviendas Fallas'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.logout();
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _MenuCard(
                  title: 'Registrar vivienda',
                  icon: Icons.home_work_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistroViviendaScreen(),
                    ),
                  ),
                ),
                _MenuCard(
                  title: 'Mapa',
                  icon: Icons.map_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapaScreen()),
                  ),
                ),
                _MenuCard(
                  title: 'Registros',
                  icon: Icons.list_alt_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrosScreen()),
                  ),
                ),
                _MenuCard(
                  title: 'Estadísticas',
                  icon: Icons.analytics_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EstadisticasScreen()),
                  ),
                ),
                _MenuCard(
                  title: 'Exportar',
                  icon: Icons.file_download_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExportarScreen()),
                  ),
                ),
                _MenuCard(
                  title: 'Sincronizar',
                  icon: Icons.sync_rounded,
                  color: AppTheme.primary,
                  onTap: () => _sincronizar(context),
                ),
                _MenuCard(
                  title: 'Configuración',
                  icon: Icons.settings_rounded,
                  color: AppTheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sincronizar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronización: subir registros pendientes al servidor')),
    );
    // TODO: subir viviendas y fotos pendientes desde LocalStorage
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.sectionCardDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
