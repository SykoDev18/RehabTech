/// Strength tier returned by [PasswordValidator.validate].
enum PasswordStrength { weak, medium, strong, veryStrong }

/// Immutable result of validating a password against the project's rules.
class PasswordValidationResult {
  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  /// All four requirements must be met for a password to be accepted.
  bool get isValid =>
      hasMinLength && hasUppercase && hasNumber && hasSpecialChar;

  int get satisfiedCount {
    var count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasNumber) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  PasswordStrength get strength {
    switch (satisfiedCount) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
        return PasswordStrength.medium;
      case 3:
        return PasswordStrength.strong;
      case 4:
      default:
        return PasswordStrength.veryStrong;
    }
  }

  /// Spanish error message describing the first unmet requirement, or null
  /// when the password is valid. Suitable as a `FormFieldValidator` return.
  String? get errorMessage {
    if (!hasMinLength) return 'Debe tener al menos 8 caracteres';
    if (!hasUppercase) return 'Debe incluir al menos una letra mayúscula';
    if (!hasNumber) return 'Debe incluir al menos un número';
    if (!hasSpecialChar) return 'Debe incluir al menos un carácter especial';
    return null;
  }
}

/// Pure-domain validator. No Flutter or Firebase dependencies — safe to unit
/// test in isolation.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _number = RegExp(r'\d');
  static final RegExp _special = RegExp(r'[!@#\$%\^&\*\(\)_\-\+=\[\]\{\};:"<>,.?/\\|`~]');

  static PasswordValidationResult validate(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= minLength,
      hasUppercase: _uppercase.hasMatch(password),
      hasNumber: _number.hasMatch(password),
      hasSpecialChar: _special.hasMatch(password),
    );
  }

  /// Convenience for use directly as a `FormField` validator.
  static String? validateAsFormField(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    return validate(value).errorMessage;
  }
}
