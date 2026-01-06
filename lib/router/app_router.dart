import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rehabtech/screens/login_screen.dart';
import 'package:rehabtech/screens/register_screen.dart';
import 'package:rehabtech/screens/forgot_password_screen.dart';
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
import 'package:rehabtech/models/exercise.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Redirect para autenticación
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation == '/forgot-password' ||
                          state.matchedLocation == '/';
      
      // Si no está logueado y no está en una ruta de auth, redirigir a login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      
      // Si está logueado y está en la ruta inicial o login, redirigir a main
      if (isLoggedIn && (state.matchedLocation == '/' || state.matchedLocation == '/login')) {
        return '/main';
      }
      
      return null;
    },
    
    routes: [
      // ============ AUTH ROUTES ============
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final isLoggedIn = FirebaseAuth.instance.currentUser != null;
          return isLoggedIn ? '/main' : '/login';
        },
      ),
      
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // ============ MAIN APP ROUTES ============
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavScreen(),
        routes: [
          // Chat con Nora
          GoRoute(
            path: 'chat/nora',
            name: 'noraChat',
            builder: (context, state) {
              final conversationId = state.uri.queryParameters['conversationId'];
              return AiChatScreen(conversationId: conversationId);
            },
          ),
          
          // Chat con terapeuta
          GoRoute(
            path: 'chat/therapist',
            name: 'therapistChat',
            builder: (context, state) => const TherapistChatScreen(),
          ),
          
          // Detalle de ejercicio
          GoRoute(
            path: 'exercise/:id',
            name: 'exerciseDetail',
            builder: (context, state) {
              final exercise = state.extra as Exercise;
              return ExerciseDetailScreen(exercise: exercise);
            },
          ),
          
          // Countdown antes de sesión
          GoRoute(
            path: 'countdown',
            name: 'countdown',
            builder: (context, state) {
              final exercise = state.extra as Exercise;
              return CountdownScreen(exercise: exercise);
            },
          ),
          
          // Sesión de terapia
          GoRoute(
            path: 'therapy-session',
            name: 'therapySession',
            builder: (context, state) {
              final exercise = state.extra as Exercise;
              return TherapySessionScreen(exercise: exercise);
            },
          ),
          
          // Reporte de sesión
          GoRoute(
            path: 'session-report',
            name: 'sessionReport',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return SessionReportScreen(
                exercise: extra['exercise'] as Exercise,
                completedReps: extra['completedReps'] as int,
                totalReps: extra['totalReps'] as int,
                elapsedSeconds: extra['elapsedSeconds'] as int,
                feedbackGood: extra['feedbackGood'] as List<String>,
                feedbackImprove: extra['feedbackImprove'] as List<String>,
                painLevel: extra['painLevel'] as int? ?? 0,
              );
            },
          ),
        ],
      ),
      
      // ============ PROFILE ROUTES ============
      GoRoute(
        path: '/profile/edit',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      
      GoRoute(
        path: '/profile/security',
        name: 'security',
        builder: (context, state) => const SecurityScreen(),
      ),
      
      GoRoute(
        path: '/profile/therapist',
        name: 'myTherapist',
        builder: (context, state) => const MyTherapistScreen(),
      ),
      
      GoRoute(
        path: '/profile/text-size',
        name: 'textSize',
        builder: (context, state) => const TextSizeScreen(),
      ),
      
      GoRoute(
        path: '/profile/high-contrast',
        name: 'highContrast',
        builder: (context, state) => const HighContrastScreen(),
      ),
      
      GoRoute(
        path: '/profile/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      GoRoute(
        path: '/profile/help',
        name: 'helpCenter',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      
      GoRoute(
        path: '/profile/privacy',
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
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
  void goToLogin() => go('/login');
  void goToRegister() => go('/register');
  void goToForgotPassword() => go('/forgot-password');
  void goToMain() => go('/main');
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
}
