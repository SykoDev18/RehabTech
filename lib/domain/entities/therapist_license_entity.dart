// Domain entity for the therapist's professional-license verification state.
// Persisted under `users/{uid}`. The verification flow writes via the
// `verifyProfessionalLicense` Cloud Function — clients can only write the
// therapist-controlled fields; Firestore rules enforce the rest.

import 'package:cloud_firestore/cloud_firestore.dart';

enum LicenseStatus {
  unverified,
  pending,
  verified,
  rejected,
  manualReview;

  String get wireValue => switch (this) {
        LicenseStatus.unverified => 'unverified',
        LicenseStatus.pending => 'pending',
        LicenseStatus.verified => 'verified',
        LicenseStatus.rejected => 'rejected',
        LicenseStatus.manualReview => 'manual_review',
      };

  /// Lenient parser — anything we don't recognise becomes [unverified] so a
  /// future schema addition can't crash old clients.
  static LicenseStatus fromString(String? value) => switch (value) {
        'verified' => LicenseStatus.verified,
        'rejected' => LicenseStatus.rejected,
        'pending' => LicenseStatus.pending,
        'manual_review' => LicenseStatus.manualReview,
        _ => LicenseStatus.unverified,
      };
}

class LicenseData {
  final String nombre;
  final String paterno;
  final String materno;
  final String titulo;
  final String institucion;
  final String fechaExpedicion;

  const LicenseData({
    required this.nombre,
    required this.paterno,
    required this.materno,
    required this.titulo,
    required this.institucion,
    required this.fechaExpedicion,
  });

  String get fullName =>
      '$nombre $paterno $materno'.replaceAll(RegExp(r'\s+'), ' ').trim();

  factory LicenseData.fromMap(Map<String, dynamic> map) {
    return LicenseData(
      nombre: (map['nombre'] as String?) ?? '',
      paterno: (map['paterno'] as String?) ?? '',
      materno: (map['materno'] as String?) ?? '',
      titulo: (map['titulo'] as String?) ?? '',
      institucion: (map['institucion'] as String?) ?? '',
      fechaExpedicion: (map['fechaExpedicion'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'paterno': paterno,
        'materno': materno,
        'titulo': titulo,
        'institucion': institucion,
        'fechaExpedicion': fechaExpedicion,
      };
}

class TherapistLicense {
  static const Duration validityWindow = Duration(days: 90);

  final String? licenseNumber;
  final LicenseStatus status;
  final LicenseData? licenseData;
  final DateTime? verifiedAt;
  final String? verificationSource;
  final String? verificationError;
  final String? speciality;
  final DateTime? licenseSubmittedAt;
  final int verificationAttempts;
  final DateTime? lastAttemptAt;

  const TherapistLicense({
    this.licenseNumber,
    this.status = LicenseStatus.unverified,
    this.licenseData,
    this.verifiedAt,
    this.verificationSource,
    this.verificationError,
    this.speciality,
    this.licenseSubmittedAt,
    this.verificationAttempts = 0,
    this.lastAttemptAt,
  });

  /// True only if the license is verified AND was verified recently
  /// enough to still be considered current. The window is documented
  /// as 90 days in the project spec.
  bool get isCurrentlyValid {
    if (status != LicenseStatus.verified || verifiedAt == null) return false;
    return DateTime.now().difference(verifiedAt!) <= validityWindow;
  }

  factory TherapistLicense.fromMap(Map<String, dynamic> map) {
    final dataMap = map['licenseData'];
    return TherapistLicense(
      licenseNumber: (map['licenseNumber'] as String?)?.trim(),
      status: LicenseStatus.fromString(map['licenseStatus'] as String?),
      licenseData: dataMap is Map<String, dynamic>
          ? LicenseData.fromMap(dataMap)
          : null,
      verifiedAt: _readTimestamp(map['verifiedAt']),
      verificationSource: map['verificationSource'] as String?,
      verificationError: map['verificationError'] as String?,
      speciality: map['speciality'] as String?,
      licenseSubmittedAt: _readTimestamp(map['licenseSubmittedAt']),
      verificationAttempts: (map['verificationAttempts'] as num?)?.toInt() ?? 0,
      lastAttemptAt: _readTimestamp(map['lastAttemptAt']),
    );
  }

  /// Map suitable for client-side writes (only therapist-controlled fields).
  /// Server-only fields (`licenseStatus`, `licenseData`, `verifiedAt`,
  /// `verificationSource`, `verificationError`, `verificationAttempts`,
  /// `lastAttemptAt`) are omitted on purpose — Firestore rules reject them.
  Map<String, dynamic> toClientWritableMap() {
    return {
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (speciality != null) 'speciality': speciality,
      if (licenseSubmittedAt != null)
        'licenseSubmittedAt': Timestamp.fromDate(licenseSubmittedAt!),
    };
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
