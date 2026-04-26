import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/utils/logger.dart';

/// Singleton wrapper around `connectivity_plus`.
///
/// Exposes a simple `Stream<bool> isOnline` and a synchronous getter for the
/// last-known status. Initialize once from `main()` — calling [initialize]
/// twice is a no-op.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _initialized = false;
  bool _isOnline = true;

  Stream<bool> get isOnline => _controller.stream;

  /// Last-known connectivity. Defaults to `true` until the first probe completes.
  bool get isCurrentlyOnline => _isOnline;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Initial probe
    _connectivity.checkConnectivity().then(_handle);

    // Subscribe to subsequent changes
    _sub = _connectivity.onConnectivityChanged.listen(_handle);

    AppLogger.info('ConnectivityService inicializado', tag: 'Connectivity');
  }

  void _handle(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline && _initialized) {
      // Avoid flapping the stream for redundant updates.
      return;
    }
    _isOnline = online;
    _controller.add(online);
    AppLogger.debug(
      'Conectividad cambió: ${online ? 'online' : 'offline'} ($results)',
      tag: 'Connectivity',
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
    _sub = null;
    _initialized = false;
  }
}
