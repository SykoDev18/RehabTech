// LicenseVerificationService — wraps the `verifyProfessionalLicense` Cloud
// Function and exposes a Firestore stream for the therapist's current
// verification state. The service owns NO mutable state; it's safe to
// instantiate per screen.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sealed result hierarchy. Every `verify` call resolves to one of these — UI
// switches on the runtime type and renders [LicenseVerificationResult] without
// ever needing to inspect raw Firebase exceptions.
// ─────────────────────────────────────────────────────────────────────────────

sealed class LicenseVerificationResult {
  const LicenseVerificationResult();

  /// User-facing Spanish copy. Always present, never null.
  String get message;
}

final class LicenseVerified extends LicenseVerificationResult {
  final LicenseData data;
  final String _message;
  const LicenseVerified(this.data, {String? message})
      : _message = message ?? 'Tu cédula fue verificada exitosamente.';

  @override
  String get message => _message;
}

final class LicenseNotFound extends LicenseVerificationResult {
  @override
  final String message;
  const LicenseNotFound(this.message);
}

final class LicenseManualReview extends LicenseVerificationResult {
  @override
  final String message;
  const LicenseManualReview(this.message);
}

final class LicenseRateLimited extends LicenseVerificationResult {
  @override
  final String message;
  const LicenseRateLimited(this.message);
}

final class LicenseInvalidInput extends LicenseVerificationResult {
  @override
  final String message;
  const LicenseInvalidInput(this.message);
}

final class LicenseVerificationError extends LicenseVerificationResult {
  @override
  final String message;
  // Detail only logged in kDebugMode — never rendered to the user.
  final String? technicalMessage;
  const LicenseVerificationError(this.message, {this.technicalMessage});
}

// ─────────────────────────────────────────────────────────────────────────────
// Test seam. Production wires this to FirebaseFunctions.instance.httpsCallable;
// tests inject a fake without depending on the Firebase plugin runtime.
// ─────────────────────────────────────────────────────────────────────────────

abstract class LicenseFunctionCaller {
  Future<Map<String, dynamic>> call(Map<String, dynamic> payload);
}

class _FirebaseFunctionsCaller implements LicenseFunctionCaller {
  final FirebaseFunctions _functions;
  _FirebaseFunctionsCaller(this._functions);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable(
      'verifyProfessionalLicense',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call<Map<dynamic, dynamic>>(payload);
    return result.data.map((k, v) => MapEntry(k.toString(), v));
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class LicenseVerificationService {
  final FirebaseFirestore _firestore;
  final LicenseFunctionCaller _caller;

  LicenseVerificationService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    LicenseFunctionCaller? caller,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _caller = caller ??
            _FirebaseFunctionsCaller(functions ?? FirebaseFunctions.instance);

  /// Validates the cedula format locally before hitting the Cloud Function.
  /// Returns null if valid, Spanish error message if invalid.
  String? validateFormat(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.isEmpty) return 'Ingresa tu número de cédula';
    if (!RegExp(r'^\d{7,8}$').hasMatch(cleaned)) {
      return 'La cédula debe tener 7 u 8 dígitos numéricos';
    }
    return null;
  }

  /// Calls the Cloud Function. Always resolves — never throws.
  Future<LicenseVerificationResult> verify({
    required String licenseNumber,
    required String speciality,
  }) async {
    try {
      final raw = await _caller.call({
        'licenseNumber': licenseNumber,
        'speciality': speciality,
      });
      return _interpretResponse(raw);
    } on FirebaseFunctionsException catch (e) {
      // Auth / permission / quota errors surface here.
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        return LicenseVerificationError(
          'No tienes permiso para verificar la cédula. Inicia sesión como terapeuta.',
          technicalMessage: '${e.code}: ${e.message}',
        );
      }
      if (e.code == 'deadline-exceeded') {
        return const LicenseVerificationError(
          'La verificación tardó demasiado. Intenta de nuevo en un momento.',
        );
      }
      return LicenseVerificationError(
        'No pudimos verificar tu cédula. Intenta más tarde.',
        technicalMessage: '${e.code}: ${e.message}',
      );
    } on TimeoutException catch (e) {
      return LicenseVerificationError(
        'La verificación tardó demasiado. Intenta de nuevo en un momento.',
        technicalMessage: e.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LicenseVerificationService] unexpected: $e');
      }
      return LicenseVerificationError(
        'Tuvimos un problema técnico. Intenta de nuevo.',
        technicalMessage: e.toString(),
      );
    }
  }

  /// Real-time Firestore stream of the therapist's license state.
  Stream<TherapistLicense> watchLicense(String uid) {
    return _licenseDocRef(uid).snapshots().map(
      (snap) {
        if (!snap.exists) return const TherapistLicense();
        return TherapistLicense.fromMap(snap.data() ?? const {});
      },
    );
  }

  DocumentReference<Map<String, dynamic>> _licenseDocRef(String uid) {
    // Therapist license data lives on `users/{uid}` in this codebase.
    return _firestore.collection('users').doc(uid);
  }

  // ───────────────────────── helpers ─────────────────────────

  @visibleForTesting
  static LicenseVerificationResult interpretForTesting(
    Map<String, dynamic> raw,
  ) =>
      _interpretResponse(raw);

  static LicenseVerificationResult _interpretResponse(
    Map<String, dynamic> raw,
  ) {
    final status = (raw['status'] as String?) ?? 'error';
    final message = (raw['message'] as String?) ?? '';
    switch (status) {
      case 'verified':
        final dataRaw = raw['licenseData'];
        if (dataRaw is Map) {
          final asMap = dataRaw.map((k, v) => MapEntry(k.toString(), v));
          return LicenseVerified(
            LicenseData.fromMap(asMap),
            message: message.isEmpty ? null : message,
          );
        }
        return LicenseVerificationError(
          'La verificación regresó sin datos. Intenta de nuevo.',
          technicalMessage: 'verified status without licenseData',
        );
      case 'not_found':
        return LicenseNotFound(message.isEmpty
            ? 'No encontramos esa cédula en el RNP de la SEP.'
            : message);
      case 'manual_review':
        return LicenseManualReview(message.isEmpty
            ? 'Tu cédula fue enviada a revisión manual.'
            : message);
      case 'rate_limited':
        return LicenseRateLimited(message.isEmpty
            ? 'Has alcanzado el límite de intentos por hoy.'
            : message);
      case 'invalid_input':
        return LicenseInvalidInput(message.isEmpty
            ? 'Datos inválidos. Revisa la cédula y la especialidad.'
            : message);
      default:
        return LicenseVerificationError(
          message.isEmpty ? 'Tuvimos un problema técnico.' : message,
          technicalMessage: 'unknown status: $status',
        );
    }
  }
}
