// Tests for LicenseVerificationService.
//
// We use a hand-rolled fake LicenseFunctionCaller (no mocktail/mockito to match
// the existing convention in test/services/nora_safety_test.dart) and
// fake_cloud_firestore for the watchLicense() stream.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehabtech/domain/entities/therapist_license_entity.dart';
import 'package:rehabtech/services/license_verification_service.dart';

class _FakeCaller implements LicenseFunctionCaller {
  Map<String, dynamic>? response;
  Object? throwValue;
  Map<String, dynamic>? lastPayload;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> payload) async {
    callCount++;
    lastPayload = payload;
    if (throwValue != null) throw throwValue!;
    return response ?? {'status': 'error', 'message': 'no response set'};
  }
}

void main() {
  group('validateFormat', () {
    final svc = LicenseVerificationService(
      firestore: FakeFirebaseFirestore(),
      caller: _FakeCaller(),
    );

    test('valid 8-digit number returns null', () {
      expect(svc.validateFormat('12345678'), isNull);
    });
    test('valid 7-digit number returns null', () {
      expect(svc.validateFormat('1234567'), isNull);
    });
    test('empty input returns Spanish error', () {
      expect(svc.validateFormat(''), isNotNull);
      expect(svc.validateFormat(''), contains('cédula'));
    });
    test('6 digits returns error', () {
      expect(svc.validateFormat('123456'), isNotNull);
    });
    test('9 digits returns error', () {
      expect(svc.validateFormat('123456789'), isNotNull);
    });
    test('letters returns error', () {
      expect(svc.validateFormat('ABCD1234'), isNotNull);
    });
    test('spaces stripped before validation', () {
      expect(svc.validateFormat('1234 5678'), isNull);
    });
    test('dashes stripped before validation', () {
      expect(svc.validateFormat('1234-5678'), isNull);
    });
  });

  group('verify — Cloud Function responses', () {
    late _FakeCaller caller;
    late LicenseVerificationService svc;

    setUp(() {
      caller = _FakeCaller();
      svc = LicenseVerificationService(
        firestore: FakeFirebaseFirestore(),
        caller: caller,
      );
    });

    test('verified response → LicenseVerified with LicenseData', () async {
      caller.response = {
        'status': 'verified',
        'message': 'ok',
        'licenseData': {
          'nombre': 'ANA',
          'paterno': 'GARCIA',
          'materno': 'LOPEZ',
          'titulo': 'Fisioterapia',
          'institucion': 'UNAM',
          'fechaExpedicion': '2018-06-15',
        },
      };
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerified>());
      expect((result as LicenseVerified).data.nombre, 'ANA');
      expect(result.data.fullName, 'ANA GARCIA LOPEZ');
    });

    test('not_found response → LicenseNotFound', () async {
      caller.response = {
        'status': 'not_found',
        'message': 'No encontramos esa cédula.',
      };
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseNotFound>());
      expect(result.message, contains('No encontramos'));
    });

    test('manual_review response → LicenseManualReview', () async {
      caller.response = {
        'status': 'manual_review',
        'message': 'En revisión.',
      };
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseManualReview>());
    });

    test('rate_limited response → LicenseRateLimited', () async {
      caller.response = {
        'status': 'rate_limited',
        'message': 'Has alcanzado el límite.',
      };
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseRateLimited>());
    });

    test('invalid_input response → LicenseInvalidInput', () async {
      caller.response = {
        'status': 'invalid_input',
        'message': 'Datos inválidos.',
      };
      final result = await svc.verify(
        licenseNumber: '123',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseInvalidInput>());
    });

    test('FirebaseFunctionsException unauthenticated → friendly error', () async {
      caller.throwValue = FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'no auth',
      );
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerificationError>());
      expect(result.message, contains('terapeuta'));
    });

    test('FirebaseFunctionsException deadline-exceeded → friendly timeout msg',
        () async {
      caller.throwValue = FirebaseFunctionsException(
        code: 'deadline-exceeded',
        message: 'too slow',
      );
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerificationError>());
      expect(result.message.toLowerCase(), contains('demasiado'));
    });

    test('TimeoutException → LicenseVerificationError with friendly text',
        () async {
      caller.throwValue = TimeoutException('boom');
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerificationError>());
      expect(result.message, isNotEmpty);
    });

    test('unknown exception → LicenseVerificationError', () async {
      caller.throwValue = StateError('odd');
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerificationError>());
    });

    test('verified response missing licenseData → error fallback', () async {
      caller.response = {'status': 'verified'};
      final result = await svc.verify(
        licenseNumber: '12345678',
        speciality: 'Fisioterapia',
      );
      expect(result, isA<LicenseVerificationError>());
    });

    test('payload is forwarded as-is to the Cloud Function', () async {
      caller.response = {
        'status': 'invalid_input',
        'message': 'noop',
      };
      await svc.verify(
        licenseNumber: '12 34-5678',
        speciality: 'Kinesiología',
      );
      expect(caller.lastPayload, {
        'licenseNumber': '12 34-5678',
        'speciality': 'Kinesiología',
      });
    });
  });

  group('LicenseStatus.fromString', () {
    test('verified', () {
      expect(LicenseStatus.fromString('verified'), LicenseStatus.verified);
    });
    test('rejected', () {
      expect(LicenseStatus.fromString('rejected'), LicenseStatus.rejected);
    });
    test('manual_review', () {
      expect(
        LicenseStatus.fromString('manual_review'),
        LicenseStatus.manualReview,
      );
    });
    test('pending', () {
      expect(LicenseStatus.fromString('pending'), LicenseStatus.pending);
    });
    test('null → unverified', () {
      expect(LicenseStatus.fromString(null), LicenseStatus.unverified);
    });
    test('garbage → unverified', () {
      expect(LicenseStatus.fromString('foo'), LicenseStatus.unverified);
    });
  });

  group('TherapistLicense.fromMap / isCurrentlyValid', () {
    test('verified within 90 days is current', () {
      final lic = TherapistLicense.fromMap({
        'licenseStatus': 'verified',
        'verifiedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
      });
      expect(lic.isCurrentlyValid, isTrue);
    });

    test('verified > 90 days is no longer current', () {
      final lic = TherapistLicense.fromMap({
        'licenseStatus': 'verified',
        'verifiedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 120)),
        ),
      });
      expect(lic.isCurrentlyValid, isFalse);
    });

    test('rejected is never current even with recent timestamp', () {
      final lic = TherapistLicense.fromMap({
        'licenseStatus': 'rejected',
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
      });
      expect(lic.isCurrentlyValid, isFalse);
    });
  });

  group('watchLicense', () {
    test('emits an unverified license when doc does not exist', () async {
      final fake = FakeFirebaseFirestore();
      final svc = LicenseVerificationService(
        firestore: fake,
        caller: _FakeCaller(),
      );
      final lic = await svc.watchLicense('uid_x').first;
      expect(lic.status, LicenseStatus.unverified);
    });

    test('emits a verified license when the doc has license fields', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('users').doc('uid_y').set({
        'licenseStatus': 'verified',
        'licenseNumber': '12345678',
        'verifiedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
        'licenseData': {
          'nombre': 'ANA',
          'paterno': 'GARCIA',
          'materno': 'LOPEZ',
          'titulo': 'Fisioterapia',
          'institucion': 'UNAM',
          'fechaExpedicion': '2018-06-15',
        },
      });
      final svc = LicenseVerificationService(
        firestore: fake,
        caller: _FakeCaller(),
      );
      final lic = await svc.watchLicense('uid_y').first;
      expect(lic.status, LicenseStatus.verified);
      expect(lic.isCurrentlyValid, isTrue);
      expect(lic.licenseData?.fullName, 'ANA GARCIA LOPEZ');
    });
  });
}
