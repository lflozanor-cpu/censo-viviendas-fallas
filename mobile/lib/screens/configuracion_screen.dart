import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../storage/local_storage.dart';
import '../theme/app_theme.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late TextEditingController _urlController;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _urlController.text = context.read<ApiService>().baseUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la URL del servidor')),
      );
      return;
    }
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL debe comenzar con http:// o https://')),
      );
      return;
    }
    setState(() => _saving = true);
    final api = context.read<ApiService>();
    await LocalStorage.saveBaseUrl(url);
    api.setBaseUrl(url);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL guardada. Se usará en la próxima conexión.')),
      );
    }
  }

  void _usarWiFiLocal() {
    _urlController.text = ApiService.urlLocal;
  }

  void _usarNgrok() {
    _urlController.text = ApiService.urlCampoDefault;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTheme.sectionTitle('URL del servidor', icon: Icons.link),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'En cada celular puede usar la misma URL o una distinta (ej. WiFi local en oficina, ngrok en campo).',
              style: TextStyle(fontSize: 13, color: AppTheme.secondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.sectionCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL base del API',
                    hintText: 'https://xxx.ngrok-free.dev/api o http://192.168.0.5:8000/api',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _usarWiFiLocal,
                      icon: const Icon(Icons.wifi_rounded, size: 18),
                      label: const Text('WiFi local'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _usarNgrok,
                      icon: const Icon(Icons.cloud_rounded, size: 18),
                      label: const Text('ngrok (campo)'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _guardar,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(_saving ? 'Guardando...' : 'Guardar URL'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
