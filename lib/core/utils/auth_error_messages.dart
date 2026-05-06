import 'package:firebase_auth/firebase_auth.dart';

/// Spanish-language mappers for Firebase Auth error codes.
///
/// Three call sites use these:
///  * Login → [mapSignInError]
///  * Register → [mapSignUpError]
///  * Verify-email "Reenviar" → [mapResendVerificationError]
///
/// Anything not in the switch returns a friendly generic message — never
/// the raw Firebase string, which leaks English UX into the Spanish app.

String mapSignInError(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No existe una cuenta con este correo.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Contraseña incorrecta.';
    case 'invalid-email':
      return 'El formato del correo no es válido.';
    case 'user-disabled':
      return 'Esta cuenta ha sido desactivada. Contacta a soporte.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera unos minutos.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet.';
    default:
      return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}

String mapSignUpError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'Este correo ya tiene una cuenta. ¿Quieres iniciar sesión?';
    case 'weak-password':
      return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
    case 'invalid-email':
      return 'El formato del correo no es válido.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
    default:
      return 'Error al crear la cuenta. Intenta de nuevo.';
  }
}

String mapResendVerificationError(FirebaseAuthException e) {
  switch (e.code) {
    case 'too-many-requests':
      return 'Has solicitado demasiados correos. Espera unos minutos.';
    case 'network-request-failed':
      return 'Sin conexión. Verifica tu internet.';
    default:
      return 'No se pudo reenviar el correo. Intenta de nuevo.';
  }
}
