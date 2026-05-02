import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rehabtech/data/repositories/auth_repository_impl.dart';

import '../../_helpers/firebase_test_setup.dart';

/// Minimal subclass of MockFirebaseAuth that throws on the configured method.
/// Used to verify that AuthRepositoryImpl does NOT swallow FirebaseAuthException
/// — the screen layer relies on the original error code to map to Spanish copy.
class _ThrowingMockAuth extends MockFirebaseAuth {
  _ThrowingMockAuth(this._toThrow) : super(signedIn: false);
  final Object _toThrow;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw _toThrow;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw _toThrow;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async => throw _toThrow;
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();

    // Stub plugin channels that AuthRepositoryImpl reaches into during
    // sign-in/sign-out (Crashlytics user ID + GoogleSignIn.signOut()).
    const channels = [
      'plugins.flutter.io/firebase_crashlytics',
      'plugins.flutter.io/google_sign_in',
    ];
    for (final name in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
  });

  group('AuthRepositoryImpl — currentUser / authStateChanges', () {
    test('currentUser is null when not signed in', () {
      final auth = MockFirebaseAuth(signedIn: false);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      expect(repo.currentUser, isNull);
    });

    test('currentUser returns the mock user when signed in', () {
      final user = MockUser(uid: 'patient-1', email: 'p@example.com');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      expect(repo.currentUser?.uid, equals('patient-1'));
      expect(repo.currentUser?.email, equals('p@example.com'));
    });

    test('authStateChanges emits the current user', () async {
      final user = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      final emitted = await repo.authStateChanges.first;
      expect(emitted?.uid, equals('u1'));
    });
  });

  group('AuthRepositoryImpl — signInWithEmail', () {
    test('returns UserCredential whose user matches the configured mock', () async {
      final user = MockUser(uid: 'patient-1', email: 'p@example.com');
      final auth = MockFirebaseAuth(mockUser: user);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      final cred = await repo.signInWithEmail('p@example.com', 'secret');

      expect(cred.user, isNotNull);
      expect(cred.user!.uid, equals('patient-1'));
    });

    test('propagates FirebaseAuthException with code "wrong-password"', () async {
      final auth = _ThrowingMockAuth(
        FirebaseAuthException(code: 'wrong-password', message: 'wrong'),
      );
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      await expectLater(
        () => repo.signInWithEmail('p@example.com', 'bad'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'wrong-password',
          ),
        ),
      );
    });

    test('propagates FirebaseAuthException with code "user-not-found"', () async {
      final auth = _ThrowingMockAuth(
        FirebaseAuthException(code: 'user-not-found'),
      );
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      await expectLater(
        () => repo.signInWithEmail('missing@example.com', 'secret'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });

    test('propagates FirebaseAuthException with code "invalid-credential"', () async {
      final auth = _ThrowingMockAuth(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      await expectLater(
        () => repo.signInWithEmail('p@example.com', 'bad'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl — createUserWithEmail', () {
    test('returns a UserCredential with a non-null user', () async {
      // Note: firebase_auth_mocks generates a fresh anonymous user for
      // createUser regardless of the configured mockUser, so we verify the
      // shape of the returned credential rather than a specific uid.
      final auth = MockFirebaseAuth();
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      final cred = await repo.createUserWithEmail('new@example.com', 'secret');
      expect(cred.user, isNotNull);
      expect(cred.user!.uid, isNotEmpty);
    });

    test('propagates FirebaseAuthException with code "email-already-in-use"',
        () async {
      final auth = _ThrowingMockAuth(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      await expectLater(
        () => repo.createUserWithEmail('dup@example.com', 'secret'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'email-already-in-use',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl — sendPasswordResetEmail', () {
    test('completes when mock auth accepts the email', () async {
      final auth = MockFirebaseAuth();
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      await expectLater(
        repo.sendPasswordResetEmail('p@example.com'),
        completes,
      );
    });

    test('propagates FirebaseAuthException with code "invalid-email"', () async {
      final auth = _ThrowingMockAuth(
        FirebaseAuthException(code: 'invalid-email'),
      );
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      await expectLater(
        () => repo.sendPasswordResetEmail('not-an-email'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'invalid-email',
          ),
        ),
      );
    });
  });

  group('AuthRepositoryImpl — signOut', () {
    test('clears currentUser', () async {
      final user = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());
      expect(repo.currentUser, isNotNull);

      await repo.signOut();
      expect(repo.currentUser, isNull);
    });
  });

  group('AuthRepositoryImpl — reauthenticate', () {
    test('throws when no user is signed in', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final repo = AuthRepositoryImpl(auth: auth, googleSignIn: GoogleSignIn());

      await expectLater(
        () => repo.reauthenticate('whatever'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
