/// Phases a rep can be in during one full range-of-motion cycle.
enum RepPhase { waiting, descending, bottom, ascending, top }

/// State machine that counts full-range-of-motion reps from a stream of
/// joint angles. Generic — caller provides [bottomThreshold] and [topThreshold].
class RepPhaseMachine {
  RepPhaseMachine({
    required this.bottomThreshold,
    required this.topThreshold,
    Duration minRepInterval = const Duration(milliseconds: 800),
    DateTime Function() now = _defaultNow,
  })  : _minRepInterval = minRepInterval,
        _now = now,
        assert(bottomThreshold < topThreshold,
            'bottomThreshold must be < topThreshold');

  final double bottomThreshold;
  final double topThreshold;
  final Duration _minRepInterval;
  final DateTime Function() _now;

  RepPhase _phase = RepPhase.waiting;
  DateTime? _lastRepAt;
  int _repCount = 0;

  RepPhase get phase => _phase;
  int get repCount => _repCount;

  /// Feeds the latest measured angle. Returns true when a rep just counted.
  bool update(double angle) {
    final atBottom = angle <= bottomThreshold;
    final atTop = angle >= topThreshold;

    switch (_phase) {
      case RepPhase.waiting:
        if (atTop) {
          _phase = RepPhase.top;
        } else if (atBottom) {
          _phase = RepPhase.bottom;
        }
        break;
      case RepPhase.top:
        if (atBottom) {
          _phase = RepPhase.bottom;
        } else if (angle < topThreshold) {
          _phase = RepPhase.descending;
        }
        break;
      case RepPhase.descending:
        if (atBottom) _phase = RepPhase.bottom;
        break;
      case RepPhase.bottom:
        if (angle > bottomThreshold) _phase = RepPhase.ascending;
        break;
      case RepPhase.ascending:
        if (atTop) {
          if (_canCountRep()) {
            _repCount++;
            _lastRepAt = _now();
            _phase = RepPhase.top;
            return true;
          }
          _phase = RepPhase.top;
        }
        break;
    }
    return false;
  }

  bool _canCountRep() {
    if (_lastRepAt == null) return true;
    return _now().difference(_lastRepAt!) >= _minRepInterval;
  }

  void reset() {
    _phase = RepPhase.waiting;
    _lastRepAt = null;
    _repCount = 0;
  }

  static DateTime _defaultNow() => DateTime.now();
}
