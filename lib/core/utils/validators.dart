/// Form validators for common input validation
class Validators {
  Validators._();
  
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }
  
  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
  
  /// Validate password with confirmation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
  
  /// Validate required field
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  /// Validate name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }
  
  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }
  
  /// Validate minimum length
  static String? minLength(String? value, int min, [String fieldName = 'Este campo']) {
    if (value == null || value.length < min) {
      return '$fieldName debe tener al menos $min caracteres';
    }
    return null;
  }
  
  /// Validate maximum length
  static String? maxLength(String? value, int max, [String fieldName = 'Este campo']) {
    if (value != null && value.length > max) {
      return '$fieldName no puede tener más de $max caracteres';
    }
    return null;
  }
  
  /// Validate number
  static String? number(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (double.tryParse(value) == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }
  
  /// Validate age
  static String? age(String? value) {
    if (value == null || value.isEmpty) {
      return 'La edad es requerida';
    }
    final age = int.tryParse(value);
    if (age == null || age < 0 || age > 150) {
      return 'Ingresa una edad válida';
    }
    return null;
  }
}
