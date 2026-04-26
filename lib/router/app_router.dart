import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rehabtech/services/analytics_service.dart';
import 'package:rehabtech/screens/login_screen.dart';
import 'package:rehabtech/screens/register_screen.dart';
import 'package:rehabtech/screens/forgot_password_screen.dart';
import 'package:rehabtech/core/transitions/transition_helper.dart';
import 'package:rehabtech/screens/onboarding/onboarding_screen.dart';
import 'package:rehabtech/screens/main/main_nav_screen.dart';
import 'package:rehabtech/screens/main/ai_chat_screen.dart';
import 'package:rehabtech/screens/main/therapist_chat_screen.dart';
import 'package:rehabtech/screens/main/exercise_detail_screen.dart';
import 'package:rehabtech/screens/main/countdown_screen.dart';
import 'package:rehabtech/screens/main/therapy_session_screen.dart';
import 'package:rehabtech/screens/main/session_report_screen.dart';
import 'package:rehabtech/screens/profile/edit_profile_screen.dart';
import 'package:rehabtech/screens/profile/security_screen.dart';
import 'package:rehabtech/screens/profile/my_therapist_screen.dart';
import 'package:rehabtech/screens/profile/text_size_screen.dart';
import 'package:rehabtech/screens/profile/high_contrast_screen.dart';
import 'package:rehabtech/screens/profile/notifications_screen.dart';
import 'package:rehabtech/screens/profile/help_center_screen.dart';
import 'package:rehabtech/screens/profile/privacy_policy_screen.dart';
import 'package:rehabtech/screens/achievements/achievements_screen.dart';
import 'package:rehabtech/screens/therapist/therapist_main_nav_screen.dart';
import 'package:rehabtech/models/exercise.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Variable para cachear el tipo de usuario
  static String? _cachedUserType;

  // Cache del flag de onboarding para evitar leer SharedPreferences en
  // cada redirect. Se invalida via [markOnboardingCompleted].
  static bool? _cachedOnboardingDone;

  // Función para obtener el tipo de usuario.
  //
  // CRÍTICO: este método se invoca desde el redirect de GoRouter, que
  // bloquea la navegación hasta que resuelva. Si Firestore queda esperando
  // red en un dispositivo offline, la UI se congela. Por eso:
  //  1) Intentamos primero el cache local (Source.cache) que retorna al
  //     instante si el documento ya fue descargado alguna vez.
  //  2) Si no hay cache, vamos al servidor con timeout corto.
  //  3) Si todo falla, asumimos 'patient' para no bloquear.
  static Future<String?> getUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (_cachedUserType != null) return _cachedUserType;

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // 1) Cache primero — offline-friendly.
    try {
      final cached =
          await docRef.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        _cachedUserType = cached.data()?['userType'] as String? ?? 'patient';
        return _cachedUserType;
      }
    } catch (_) {
      // Cache miss en primer arranque es normal — caemos al servidor.
    }

    // 2) Servidor con timeout para no bloquear el redirect indefinidamente.
    try {
      final doc = await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));
      if (doc.exists) {
        _cachedUserType = doc.data()?['userType'] as String? ?? 'patient';
        return _cachedUserType;
      }
    } catch (_) {
      // Sin red o timeout — usamos default sin bloquear navegación.
    }
    return 'patient';
  }

  // Limpiar cache al cerrar sesión
  static void clearUserTypeCache() {
    _cachedUserType = null;
  }

  /// Lee (y cachea) el flag de onboarding desde SharedPreferences.
  static Future<bool> isOnboardingCompleted() async {
    if (_cachedOnboardingDone != null) return _cachedOnboardingDone!;
    final prefs = await SharedPreferences.getInstance();
    _cachedOnboardingDone = prefs.getBool(onboardingCompletedKey) ?? false;
    return _cachedOnboardingDone!;
  }

  /// Llamar tras finalizar el onboarding para que el cache refleje el
  /// nuevo estado sin tener que volver a leer SharedPreferences.
  static void markOnboardingCompleted() {
    _cachedOnboardingDone = true;
  }
  
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    observers: [AnalyticsService().observer],
    
    // Redirect para autenticación + onboarding
    redirect: (context, state) async {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      final isOnboardingRoute = loc == '/onboarding';
      final isAuthRoute = loc == '/login' ||
                          loc == '/register' ||
                          loc == '/forgot-password' ||
                          loc == '/';

      // Onboarding gate: aplica solo a usuarios sin sesión iniciada.
      // Usuarios autenticados nunca ven onboarding.
      if (!isLoggedIn) {
        final onboardingDone = await isOnboardingCompleted();
        if (!onboardingDone && !isOnboardingRoute) {
          return '/onboarding';
        }
        if (onboardingDone && isOnboardingRoute) {
          return '/login';
        }
      }

      // Si no está logueado y no está en una ruta de auth/onboarding, redirigir a login
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        return '/login';
      }

      // Si está logueado y está en la ruta inicial, login u onboarding
      if (isLoggedIn && (loc == '/' || loc == '/login' || loc == '/onboarding')) {
        final userType = await getUserType();
        return userType == 'therapist' ? '/therapist' : '/main';
      }

      return null;
    },
    
    routes: [
      // ============ AUTH ROUTES ============
      GoRoute(
        path: '/',
        redirect: (context, state) async {
          final isLoggedIn = FirebaseAuth.instance.currentUser != null;
          if (!isLoggedIn) return '/login';
          final userType = await getUserType();
          return userType == 'therapist' ? '/therapist' : '/main';
        },
      ),
      
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const LoginScreen()),
      ),

      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const RegisterScreen()),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const ForgotPasswordScreen()),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const OnboardingScreen()),
      ),
      
      // ============ MAIN APP ROUTES (PATIENT) ============
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavScreen(),
        routes: [
          // Chat con Nora
          GoRoute(
            path: 'chat/nora',
            name: 'noraChat',
            pageBuilder: (context, state) {
              final conversationId = state.uri.queryParameters['conversationId'];
              return TransitionHelper.slideFromRight(
                child: AiChatScreen(conversationId: conversationId),
              );
            },
          ),

          // Chat con terapeuta
          GoRoute(
            path: 'chat/therapist',
            name: 'therapistChat',
            pageBuilder: (context, state) => TransitionHelper.slideFromRight(
              child: const TherapistChatScreen(),
            ),
          ),

          // Detalle de ejercicio (soporta deep linking por ID)
          GoRoute(
            path: 'exercise/:id',
            name: 'exerciseDetail',
            pageBuilder: (context, state) {
              // Primero intentar obtener de extra (navegación interna)
              final extraExercise = state.extra as Exercise?;
              if (extraExercise != null) {
                return TransitionHelper.slideFromRight(
                  child: ExerciseDetailScreen(exercise: extraExercise),
                );
              }

              // Si no hay extra, buscar por ID (deep link)
              final id = state.pathParameters['id']!;
              final exercise = allExercises.where((e) => e.id == id).firstOrNull;

              if (exercise != null) {
                return TransitionHelper.slideFromRight(
                  child: ExerciseDetailScreen(exercise: exercise),
                );
              }

              // Ejercicio no encontrado - mostrar error
              return TransitionHelper.fade(
                child: Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ejercicio "$id" no encontrado'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/main'),
                          child: const Text('Volver al inicio'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Countdown antes de sesión: scaleFade para marcar entrada a sesión
          GoRoute(
            path: 'countdown',
            name: 'countdown',
            pageBuilder: (context, state) {
              final exercise = state.extra as Exercise;
              return TransitionHelper.scaleFade(
                child: CountdownScreen(exercise: exercise),
              );
            },
          ),

          // Sesión de terapia
          GoRoute(
            path: 'therapy-session',
            name: 'therapySession',
            pageBuilder: (context, state) {
              final exercise = state.extra as Exercise;
              return TransitionHelper.fade(
                child: TherapySessionScreen(exercise: exercise),
              );
            },
          ),

          // Reporte de sesión
          GoRoute(
            path: 'session-report',
            name: 'sessionReport',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return TransitionHelper.scaleFade(
                child: SessionReportScreen(
                  exercise: extra['exercise'] as Exercise,
                  completedReps: extra['completedReps'] as int,
                  totalReps: extra['totalReps'] as int,
                  elapsedSeconds: extra['elapsedSeconds'] as int,
                  feedbackGood: extra['feedbackGood'] as List<String>,
                  feedbackImprove: extra['feedbackImprove'] as List<String>,
                  painLevel: extra['painLevel'] as int? ?? 0,
                ),
              );
            },
          ),
        ],
      ),
      
      // ============ PROFILE ROUTES ============
      GoRoute(
        path: '/profile/edit',
        name: 'editProfile',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const EditProfileScreen()),
      ),

      GoRoute(
        path: '/profile/security',
        name: 'security',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const SecurityScreen()),
      ),

      GoRoute(
        path: '/profile/therapist',
        name: 'myTherapist',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const MyTherapistScreen()),
      ),

      GoRoute(
        path: '/profile/text-size',
        name: 'textSize',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const TextSizeScreen()),
      ),

      GoRoute(
        path: '/profile/high-contrast',
        name: 'highContrast',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const HighContrastScreen()),
      ),

      GoRoute(
        path: '/profile/notifications',
        name: 'notifications',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const NotificationsScreen()),
      ),

      GoRoute(
        path: '/profile/help',
        name: 'helpCenter',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const HelpCenterScreen()),
      ),

      GoRoute(
        path: '/profile/privacy',
        name: 'privacyPolicy',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const PrivacyPolicyScreen()),
      ),

      GoRoute(
        path: '/profile/achievements',
        name: 'achievements',
        pageBuilder: (context, state) =>
            TransitionHelper.slideFromRight(child: const AchievementsScreen()),
      ),

      // ============ THERAPIST APP ROUTES ============
      GoRoute(
        path: '/therapist',
        name: 'therapistMain',
        builder: (context, state) => const TherapistMainNavScreen(),
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/main'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Extensión para navegación más fácil
extension GoRouterExtension on BuildContext {
  void goToLogin() {
    AppRouter.clearUserTypeCache();
    go('/login');
  }
  void goToRegister() => go('/register');
  void goToForgotPassword() => go('/forgot-password');
  void goToMain() => go('/main');
  void goToTherapistMain() => go('/therapist');
  void goToNoraChat({String? conversationId}) {
    if (conversationId != null) {
      go('/main/chat/nora?conversationId=$conversationId');
    } else {
      go('/main/chat/nora');
    }
  }
  void goToTherapistChat() => go('/main/chat/therapist');
  void goToExerciseDetail(Exercise exercise) => 
      go('/main/exercise/${exercise.id}', extra: exercise);
  void goToEditProfile() => go('/profile/edit');
  void goToSecurity() => go('/profile/security');
  void goToMyTherapist() => go('/profile/therapist');
  void goToTextSize() => go('/profile/text-size');
  void goToHighContrast() => go('/profile/high-contrast');
  void goToNotifications() => go('/profile/notifications');
  void goToHelpCenter() => go('/profile/help');
  void goToPrivacyPolicy() => go('/profile/privacy');
  void goToAchievements() => go('/profile/achievements');
}
