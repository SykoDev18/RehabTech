// Mocks the firebase_core platform interface so calls to
// `Firebase.initializeApp()` succeed in widget tests. Does NOT mock
// FirebaseAuth/Firestore platform implementations — code that uses
// `FirebaseAuth.instance` or `FirebaseFirestore.instance` still needs
// either dependency injection or a more complete platform mock.
//
// Use in widget tests like:
//
//   setUpAll(() async {
//     setupFirebaseCoreMocks();
//     await Firebase.initializeApp();
//   });
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTestAppName = '[DEFAULT]';

const _kTestOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:android:0',
  messagingSenderId: '1234567890',
  projectId: 'test-project',
);

class _FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  _FakeFirebaseAppPlatform(super.name, super.options);
}

class _FakeFirebasePlatform extends FirebasePlatform {
  _FakeFirebasePlatform() : super();

  final List<FirebaseAppPlatform> _registered = <FirebaseAppPlatform>[];

  @override
  FirebaseAppPlatform app([String name = _kTestAppName]) {
    return _registered.firstWhere(
      (a) => a.name == name,
      orElse: () => _FakeFirebaseAppPlatform(name, _kTestOptions),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final app = _FakeFirebaseAppPlatform(
      name ?? _kTestAppName,
      options ?? _kTestOptions,
    );
    _registered.add(app);
    return app;
  }

  @override
  List<FirebaseAppPlatform> get apps => _registered;
}

bool _setUp = false;

/// Wires the firebase_core platform mock into [FirebasePlatform.instance] and
/// silences MethodChannel calls that the SDKs make on import.
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_setUp) return;
  _setUp = true;

  FirebasePlatform.instance = _FakeFirebasePlatform();

  // Stub MethodChannel handlers used by firebase_auth and firebase_messaging
  // during static-instance bootstrap so they don't throw when widgets call
  // `FirebaseAuth.instance` etc. during build().
  const channels = [
    'plugins.flutter.io/firebase_core',
    'plugins.flutter.io/firebase_auth',
    'plugins.flutter.io/firebase_firestore',
  ];
  for (final name in channels) {
    final channel = MethodChannel(name);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      // No app registered → caller falls back to its in-memory default.
      return null;
    });
  }
}
