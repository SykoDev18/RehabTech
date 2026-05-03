/// Domain-level error for appointment operations.
///
/// [message] is always Spanish and safe to show in a SnackBar — the repository
/// catches Firebase / network errors and rethrows this with a localized
/// message rather than leaking platform error codes.
class AppointmentException implements Exception {
  final String message;
  const AppointmentException(this.message);

  @override
  String toString() => 'AppointmentException: $message';
}
