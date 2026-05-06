import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/core/utils/auth_error_messages.dart';

FirebaseAuthException _exc(String code, [String? message]) =>
    FirebaseAuthException(code: code, message: message);

void main() {
  group('mapSignInError', () {
    test('user-not-found returns Spanish "no existe" message', () {
      expect(
        mapSignInError(_exc('user-not-found')),
        'No existe una cuenta con este correo.',
      );
    });

    test('wrong-password and invalid-credential map to the same message', () {
      expect(
        mapSignInError(_exc('wrong-password')),
        'Contraseña incorrecta.',
      );
      expect(
        mapSignInError(_exc('invalid-credential')),
        'Contraseña incorrecta.',
      );
    });

    test('user-disabled mentions support contact', () {
      final m = mapSignInError(_exc('user-disabled'));
      expect(m, contains('desactivada'));
      expect(m, contains('soporte'));
    });

    test('too-many-requests asks user to wait', () {
      expect(
        mapSignInError(_exc('too-many-requests')),
        'Demasiados intentos. Espera unos minutos.',
      );
    });

    test('network-request-failed mentions internet', () {
      expect(
        mapSignInError(_exc('network-request-failed')),
        'Sin conexión. Verifica tu internet.',
      );
    });

    test('unknown code returns generic Spanish fallback', () {
      expect(
        mapSignInError(_exc('something-weird')),
        'Error al iniciar sesión. Intenta de nuevo.',
      );
    });
  });

  group('mapSignUpError', () {
    test('email-already-in-use suggests signing in', () {
      final m = mapSignUpError(_exc('email-already-in-use'));
      expect(m, contains('ya tiene una cuenta'));
    });

    test('weak-password mentions length', () {
      expect(
        mapSignUpError(_exc('weak-password')),
        'La contraseña es muy débil. Usa al menos 8 caracteres.',
      );
    });

    test('invalid-email is mapped', () {
      expect(
        mapSignUpError(_exc('invalid-email')),
        'El formato del correo no es válido.',
      );
    });

    test('network-request-failed mentions internet', () {
      expect(
        mapSignUpError(_exc('network-request-failed')),
        'Sin conexión. Verifica tu internet e intenta de nuevo.',
      );
    });

    test('unknown code returns generic Spanish fallback', () {
      expect(
        mapSignUpError(_exc('weirdness')),
        'Error al crear la cuenta. Intenta de nuevo.',
      );
    });
  });

  group('mapResendVerificationError', () {
    test('too-many-requests is mapped to wait message', () {
      expect(
        mapResendVerificationError(_exc('too-many-requests')),
        'Has solicitado demasiados correos. Espera unos minutos.',
      );
    });

    test('unknown code returns generic resend-failed Spanish', () {
      expect(
        mapResendVerificationError(_exc('whatever')),
        'No se pudo reenviar el correo. Intenta de nuevo.',
      );
    });
  });
}
