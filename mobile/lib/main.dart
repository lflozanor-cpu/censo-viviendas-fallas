import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'storage/local_storage.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  final savedBaseUrl = await LocalStorage.getBaseUrl();
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    };
    runApp(SplashWrapper(initialBaseUrl: savedBaseUrl));
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

/// Primera pantalla mínima para evitar crash en algunos dispositivos (userfaultfd/GPU).
/// Tras un breve retraso se construye la app real.
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key, this.initialBaseUrl});

  final String? initialBaseUrl;

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Scaffold(
          backgroundColor: Colors.blue.shade700,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text('Cargando...', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ),
      );
    }
    return MyApp(initialBaseUrl: widget.initialBaseUrl);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialBaseUrl});

  final String? initialBaseUrl;

  @override
  Widget build(BuildContext context) {
    final api = ApiService(initialBaseUrl: initialBaseUrl);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Censo Viviendas Fallas',
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}