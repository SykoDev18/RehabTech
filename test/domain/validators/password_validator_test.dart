import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/validators/password_validator.dart';

void main() {
  group('PasswordValidator.validate', () {
    test('cadena vacía no cumple ningún requisito', () {
      final result = PasswordValidator.validate('');
      expect(result.hasMinLength, isFalse);
      expect(result.hasUppercase, isFalse);
      expect(result.hasNumber, isFalse);
      expect(result.hasSpecialChar, isFalse);
      expect(result.satisfiedCount, 0);
      expect(result.isValid, isFalse);
      expect(result.strength, PasswordStrength.weak);
    });

    test('exactamente 8 caracteres marca hasMinLength', () {
      expect(PasswordValidator.validate('aaaaaaaa').hasMinLength, isTrue);
      expect(PasswordValidator.validate('aaaaaaa').hasMinLength, isFalse);
    });

    test('detecta mayúscula', () {
      expect(PasswordValidator.validate('aAbcdefg').hasUppercase, isTrue);
      expect(PasswordValidator.validate('abcdefgh').hasUppercase, isFalse);
    });

    test('detecta número', () {
      expect(PasswordValidator.validate('abcdefg1').hasNumber, isTrue);
      expect(PasswordValidator.validate('abcdefgh').hasNumber, isFalse);
    });

    test('detecta carácter especial', () {
      const specials = '!@#\$%^&*()_-+=[]{};:"<>,.?/\\|`~';
      for (final ch in specials.split('')) {
        final pwd = 'Aaaaaaa1$ch';
        expect(
          PasswordValidator.validate(pwd).hasSpecialChar,
          isTrue,
          reason: 'Debe detectar "$ch"',
        );
      }
      expect(
        PasswordValidator.validate('AbcDefg1').hasSpecialChar,
        isFalse,
      );
    });

    test('cumple los 4 requisitos => veryStrong y errorMessage null', () {
      final r = PasswordValidator.validate('Abcdefg1!');
      expect(r.isValid, isTrue);
      expect(r.satisfiedCount, 4);
      expect(r.strength, PasswordStrength.veryStrong);
      expect(r.errorMessage, isNull);
    });

    test('mapping de satisfiedCount a strength', () {
      // 0-1 -> weak, 2 -> medium, 3 -> strong, 4 -> veryStrong
      // 'a' cumple 0 -> weak
      expect(
        PasswordValidator.validate('a').strength,
        PasswordStrength.weak,
      );
      // 'aA' cumple 1 (uppercase) -> weak
      expect(
        PasswordValidator.validate('aA').strength,
        PasswordStrength.weak,
      );
      // 'aA1' cumple 2 (uppercase + number) -> medium
      expect(
        PasswordValidator.validate('aA1').strength,
        PasswordStrength.medium,
      );
      // 8 chars + uppercase + number = 3 reqs -> strong
      expect(
        PasswordValidator.validate('Abcdefg1').strength,
        PasswordStrength.strong,
      );
      // 8 chars + uppercase + number + special = 4 reqs -> veryStrong
      expect(
        PasswordValidator.validate('Abcdefg1!').strength,
        PasswordStrength.veryStrong,
      );
    });

    test('errorMessage muestra el primer requisito incumplido', () {
      expect(
        PasswordValidator.validate('').errorMessage,
        contains('al menos 8'),
      );
      expect(
        PasswordValidator.validate('abcdefgh').errorMessage,
        contains('mayúscula'),
      );
      expect(
        PasswordValidator.validate('Abcdefgh').errorMessage,
        contains('número'),
      );
      expect(
        PasswordValidator.validate('Abcdefg1').errorMessage,
        contains('carácter especial'),
      );
    });

    test('caracteres unicode (acentos) no cuentan como mayúscula extendida', () {
      // El regex es [A-Z]; ñ/Ñ y vocales acentuadas no cuentan como uppercase.
      // Esto es intencional para mantener reglas predecibles.
      expect(PasswordValidator.validate('ñabcdef1!').hasUppercase, isFalse);
      expect(PasswordValidator.validate('Ñabcdef1!').hasUppercase, isFalse);
    });

    test('solo espacios no satisface ningún requisito relevante', () {
      final r = PasswordValidator.validate('        '); // 8 espacios
      expect(r.hasMinLength, isTrue); // técnicamente sí cumple longitud
      expect(r.hasUppercase, isFalse);
      expect(r.hasNumber, isFalse);
      expect(r.hasSpecialChar, isFalse);
      expect(r.isValid, isFalse);
    });
  });

  group('PasswordValidator.validateAsFormField', () {
    test('null y vacío retornan mensaje "requerida"', () {
      expect(
        PasswordValidator.validateAsFormField(null),
        contains('requerida'),
      );
      expect(
        PasswordValidator.validateAsFormField(''),
        contains('requerida'),
      );
    });

    test('contraseña inválida retorna mensaje del primer requisito', () {
      expect(
        PasswordValidator.validateAsFormField('abc'),
        contains('al menos 8'),
      );
    });

    test('contraseña válida retorna null', () {
      expect(
        PasswordValidator.validateAsFormField('Abcdefg1!'),
        isNull,
      );
    });
  });
}
