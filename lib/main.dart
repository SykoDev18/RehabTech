import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
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
import 'presentation/widgets/common/production_error_widget.dart';
import 'router/app_router.dart';
import 'services/connectivity_service.dart';
import 'services/progress_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';

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

    // Persistencia offline de Firestore (lecturas y escrituras se cachean
    // localmente; las escrituras se replican cuando vuelve la conexión).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Crashlytics: solo recolectar en release (en debug los errores ya
    // salen por consola, recolectarlos contamina los reportes).
    // Timeout defensivo: si el plugin nativo no responde, no bloqueamos
    // el arranque por algo que tampoco vamos a usar en debug.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode)
        .timeout(const Duration(seconds: 3), onTimeout: () {});

    // Errores de framework (build/layout/paint) -> Crashlytics.
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Errores async fuera del Zone -> Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // ErrorWidget.builder: en debug mostramos la pantalla roja por defecto
    // para que sea evidente; en release mostramos un mensaje amigable.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) return ErrorWidget(details.exception);
      return const ProductionErrorWidget();
    };

    // Si hay sesión persistida desde un arranque previo, asociar el uid a
    // Crashlytics sin esperar al próximo login.
    final persistedUser = FirebaseAuth.instance.currentUser;
    if (persistedUser != null) {
      unawaited(FirebaseCrashlytics.instance.setUserIdentifier(persistedUser.uid));
    }
    
    // ─────────── Init crítico ANTES de runApp ───────────
    // Todo lo que el primer frame necesita o que tiene que existir antes
    // de que el router resuelva. Lo demás se difiere a background.

    // Firebase App Check: activamos el provider (no descarga token; eso
    // se hace lazy cuando algo lo necesita). Timeout corto por seguridad.
    await AppCheckService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => AppLogger.warning(
        'AppCheck no inicializó dentro del timeout (sin red?)',
        tag: 'App',
      ),
    );

    // .env, locale y ProgressService son lecturas locales rápidas —
    // pueden ir en paralelo y completan en <500ms.
    await Future.wait([
      dotenv.load(fileName: ".env"),
      initializeDateFormatting('es_ES', null),
      ProgressService().init(),
    ]);

    // ConnectivityService es fire-and-forget por diseño.
    ConnectivityService().initialize();
    AppLogger.info('Init crítico listo, lanzando UI', tag: 'App');

    runApp(const MyApp());

    // ─────────── Init diferido (post-runApp) ───────────
    // Estos servicios no son necesarios para el primer frame:
    //  - Analytics: se llama cuando se loguean eventos (tolera no-init)
    //  - NotificationService: getToken() puede tardar mucho sin red; el
    //    onTokenRefresh lo recupera cuando llegue, y mientras tanto la
    //    app es perfectamente usable
    // Los disparamos en paralelo y dejamos que terminen por su cuenta.
    unawaited(_initDeferredServices());
  }, (error, stackTrace) {
    // Capturar errores no manejados
    ErrorHandler().handle(error, stackTrace: stackTrace, context: 'Unhandled');
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  });
}

/// Inicialización en background de servicios no-críticos para el primer
/// frame. Cualquier fallo se tolera: los servicios están diseñados para
/// reintentar o degradar silenciosamente.
Future<void> _initDeferredServices() async {
  await Future.wait([
    AnalyticsService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => AppLogger.warning(
        'Analytics no inicializó dentro del timeout',
        tag: 'App',
      ),
    ),
    NotificationService().initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () => AppLogger.warning(
        'NotificationService timeout — el token FCM se reintentará en background',
        tag: 'App',
      ),
    ),
  ]);
  AppLogger.info('Servicios diferidos inicializados', tag: 'App');
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
            themeMode: themeProvider.effectiveThemeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // Layer accessibility overrides on top of the platform's
              // MediaQuery so the user-controlled text-scale and
              // high-contrast prefs apply app-wide. ErrorListener stays
              // inside MaterialApp for ScaffoldMessenger access.
              final base = MediaQuery.of(context);
              return MediaQuery(
                data: base.copyWith(
                  textScaler: themeProvider.textScaler,
                  highContrast: themeProvider.highContrast,
                ),
                child: ErrorListener(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
