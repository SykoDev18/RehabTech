import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Core utilities
import 'core/utils/logger.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/app_check_service.dart';

// Layered architecture imports
import 'presentation/providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/progress_service.dart';

void main() async {
  // Capturar errores de zona para logging
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializar error handler
    ErrorHandler().initialize();
    
    AppLogger.info('🚀 Iniciando RehabTech...', tag: 'App');
    
    // Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase Core inicializado', tag: 'App');
    
    // Firebase App Check (protección de APIs)
    await AppCheckService().initialize();
    
    // Cargar variables de entorno
    await dotenv.load(fileName: ".env");
    AppLogger.info('Variables de entorno cargadas', tag: 'App');
    
    // Inicializar locale
    await initializeDateFormatting('es_ES', null);
    
    // Inicializar servicios
    await ProgressService().init();
    AppLogger.info('Servicios inicializados', tag: 'App');
    
    AppLogger.info('✅ App lista para ejecutar', tag: 'App');
    
    runApp(const MyApp());
  }, (error, stackTrace) {
    // Capturar errores no manejados
    ErrorHandler().handle(error, stackTrace: stackTrace, context: 'Unhandled');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'RehabTech',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // ErrorListener debe estar dentro de MaterialApp para tener acceso a ScaffoldMessenger
              return ErrorListener(
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
