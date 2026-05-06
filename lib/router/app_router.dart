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
import 'package:rehabtech/screens/main/my_appointments_screen.dart';
import 'package:rehabtech/screens/main/my_routines_screen.dart';
import 'package:rehabtech/screens/main/ai_chat_screen.dart';
import 'package:rehabtech/screens/chat/chat_screen.dart';
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
import 'package:rehabtech/screens/profile/therapist/license_verification_screen.dart';
import 'package:rehabtech/screens/appointments/appointment_detail_screen.dart';
import 'package:rehabtech/models/exercise.dart';
import 'package:rehabtech/router/redirect_logic.dart';
import 'package:rehabtech/screens/auth/verify_email_screen.dart';
import 'package:rehabtech/screens/onboarding/therapist_onboarding_screen.dart';
import 'package:rehabtech/screens/onboarding/patient_onboarding_screen.dart';

class _UserState {
  final String userType;
  final bool? onboardingCompleted;
  const _UserState(this.userType, this.onboardingCompleted);
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // ─────────────────── User-doc cache ───────────────────
  //
  // The redirect callback runs on every navigation, including push() within
  // a screen. We cache `userType` and `onboardingCompleted` together since
  // they come from the same Firestore document — one lookup, two values.
  //
  // Offline behaviour:
  //   1. Try Source.cache (returns instantly if the doc was ever loaded).
  //   2. Otherwise hit Source.server with a 6s timeout.
  //   3. If both fail, fall back to {userType: 'patient', onboardingCompleted: null}
  //      so signed-in users on cold-starts see *something* instead of getting
  //      bounced through the redirect logic indefinitely. `null` for the
  //      onboarding flag lets [computeRedirect] decline to gate.

  static String? _cachedUserType;
  static bool? _cachedUserOnboardingCompleted;

  // App-intro carousel flag (SharedPreferences). Independent of the
  // per-user onboarding flag.
  static bool? _cachedAppIntroDone;

  /// Returns `'patient' | 'therapist' | null`. `null` only when the user is
  /// unauthenticated.
  static Future<String?> getUserType() async {
    final state = await _loadUserState();
    return state?.userType;
  }

  /// Returns whether the per-role onboarding has been completed for the
  /// current user, or `null` if the user doc hasn't been loaded yet
  /// (offline cold-start). Callers must treat `null` as "do not gate".
  static Future<bool?> getUserOnboardingCompleted() async {
    final state = await _loadUserState();
    return state?.onboardingCompleted;
  }

  static Future<_UserState?> _loadUserState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (_cachedUserType != null) {
      return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
    }

    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    // 1) Cache first — offline-friendly.
    try {
      final cached =
          await docRef.get(const GetOptions(source: Source.cache));
      if (cached.exists) {
        final data = cached.data() ?? const <String, dynamic>{};
        _cachedUserType = (data['userType'] as String?) ?? 'patient';
        _cachedUserOnboardingCompleted =
            data['onboardingCompleted'] as bool? ?? false;
        return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
      }
    } catch (_) {
      // Cache miss on first launch — fall through.
    }

    // 2) Server, with timeout to avoid wedging the redirect.
    try {
      final doc = await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));
      if (doc.exists) {
        final data = doc.data() ?? const <String, dynamic>{};
        _cachedUserType = (data['userType'] as String?) ?? 'patient';
        _cachedUserOnboardingCompleted =
            data['onboardingCompleted'] as bool? ?? false;
        return _UserState(_cachedUserType!, _cachedUserOnboardingCompleted);
      }
    } catch (_) {
      // Offline / timeout — return a permissive default so the user isn't
      // bounced. The next navigation will retry.
    }
    return const _UserState('patient', null);
  }

  /// Clears all caches that depend on the signed-in user. Call from every
  /// logout path. The `goToLogin()` extension already invokes this.
  static void clearAuthCache() {
    _cachedUserType = null;
    _cachedUserOnboardingCompleted = null;
  }

  /// Backwards-compatible alias — old call sites still call this. Both
  /// names clear the same fields.
  static void clearUserTypeCache() => clearAuthCache();

  /// Reads (and caches) whether the app-intro carousel has been completed.
  static Future<bool> isOnboardingCompleted() async {
    if (_cachedAppIntroDone != null) return _cachedAppIntroDone!;
    final prefs = await SharedPreferences.getInstance();
    _cachedAppIntroDone = prefs.getBool(onboardingCompletedKey) ?? false;
    return _cachedAppIntroDone!;
  }

  /// Call after finishing the app-intro carousel.
  static void markOnboardingCompleted() {
    _cachedAppIntroDone = true;
  }

  /// Call after finishing the per-role onboarding screen (therapist or
  /// patient). Keeps the cache in sync with the Firestore write so the
  /// next redirect doesn't bounce the user back.
  static void markUserOnboardingCompleted() {
    _cachedUserOnboardingCompleted = true;
  }
  
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    observers: [AnalyticsService().observer],
    
    // Redirect para autenticación + onboarding.
    //
    // The decision logic lives in [computeRedirect] (a pure function in
    // redirect_logic.dart) — this callback only gathers state.
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final emailVerified = user?.emailVerified ?? false;

      String? userType;
      bool? onboardingCompleted;
      if (isLoggedIn) {
        final userState = await _loadUserState();
        userType = userState?.userType;
        onboardingCompleted = userState?.onboardingCompleted;
      }

      final appIntroDone = await isOnboardingCompleted();

      return computeRedirect(RouterInputs(
        currentPath: state.matchedLocation,
        isLoggedIn: isLoggedIn,
        emailVerified: emailVerified,
        userType: userType,
        onboardingCompleted: onboardingCompleted,
        appIntroDone: appIntroDone,
      ));
    },
    
    routes: [
      // ============ AUTH ROUTES ============
      GoRoute(
        path: '/',
        // Global `redirect:` above handles all auth + onboarding routing —
        // this exists only so '/' is a valid initial location.
        redirect: (_, _) => null,
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

      GoRoute(
        path: '/verify-email',
        name: 'verifyEmail',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const VerifyEmailScreen()),
      ),

      GoRoute(
        path: '/therapist/onboarding',
        name: 'therapistOnboarding',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const TherapistOnboardingScreen()),
      ),

      GoRoute(
        path: '/patient/onboarding',
        name: 'patientOnboarding',
        pageBuilder: (context, state) =>
            TransitionHelper.fade(child: const PatientOnboardingScreen()),
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

          // Chat humano con terapeuta (paciente) o paciente (terapeuta).
          // Acepta `otherUserId` (resuelve la conversación al abrir) o
          // `conversationId` (cuando el caller ya la conoce).
          GoRoute(
            path: 'chat/therapist',
            name: 'therapistChat',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final otherUserId = extra?['otherUserId'] as String? ??
                  extra?['therapistId'] as String? ??
                  extra?['patientId'] as String?;
              final conversationId = extra?['conversationId'] as String?;
              return TransitionHelper.slideFromRight(
                child: ChatScreen(
                  otherUserId: otherUserId,
                  conversationId: conversationId,
                ),
              );
            },
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

          // Mis rutinas asignadas (paciente)
          GoRoute(
            path: 'my-routines',
            name: 'myRoutines',
            pageBuilder: (context, state) => TransitionHelper.slideFromRight(
              child: const MyRoutinesScreen(),
            ),
          ),

          // Mis citas (paciente)
          GoRoute(
            path: 'my-appointments',
            name: 'myAppointments',
            pageBuilder: (context, state) => TransitionHelper.slideFromRight(
              child: const MyAppointmentsScreen(),
            ),
            routes: [
              // Detalle de cita (paciente)
              GoRoute(
                path: ':id',
                name: 'patientAppointmentDetail',
                pageBuilder: (context, state) => TransitionHelper.slideFromRight(
                  child: AppointmentDetailScreen(
                    appointmentId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
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
        routes: [
          // Detalle de cita (terapeuta) — mismo screen, role-aware.
          GoRoute(
            path: 'appointments/:id',
            name: 'therapistAppointmentDetail',
            pageBuilder: (context, state) => TransitionHelper.slideFromRight(
              child: AppointmentDetailScreen(
                appointmentId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/license-verification',
        name: 'licenseVerification',
        pageBuilder: (context, state) => TransitionHelper.slideFromRight(
          child: const LicenseVerificationScreen(),
        ),
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
  /// Navega al chat humano. Pasa `otherUserId` cuando aún no se conoce
  /// el conversationId (el repositorio idempotentemente lo crea), o
  /// `conversationId` cuando ya se sabe (al abrir desde la lista).
  void goToTherapistChat({String? otherUserId, String? conversationId}) {
    go(
      '/main/chat/therapist',
      extra: <String, dynamic>{
        if (otherUserId != null) 'otherUserId': otherUserId,
        if (conversationId != null) 'conversationId': conversationId,
      },
    );
  }
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
  void goToMyRoutines() => go('/main/my-routines');
  void goToMyAppointments() => go('/main/my-appointments');
  void goToLicenseVerification() => go('/license-verification');
  void goToVerifyEmail() => go('/verify-email');
  void goToTherapistOnboarding() => go('/therapist/onboarding');
  void goToPatientOnboarding() => go('/patient/onboarding');
}
