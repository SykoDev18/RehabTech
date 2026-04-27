import 'package:flutter/foundation.dart';
import 'package:rehabtech/core/utils/logger.dart';

/// Result of sanitizing a user input destined for Nora.
///
/// One of three terminal states:
/// - [allowed]   → safe to forward to the model verbatim ([sanitized] == cleaned input)
/// - [softFlag] → forward to the model, but with a context reminder prepended
/// - [blocked]   → never call the model; render the canned safe response instead
class NoraSanitizationResult {
  final NoraSanitizationOutcome outcome;
  final String sanitized;
  final String? blockedReason;

  const NoraSanitizationResult._(this.outcome, this.sanitized, this.blockedReason);

  factory NoraSanitizationResult.allowed(String sanitized) =>
      NoraSanitizationResult._(NoraSanitizationOutcome.allowed, sanitized, null);

  factory NoraSanitizationResult.softFlag(String sanitized) =>
      NoraSanitizationResult._(NoraSanitizationOutcome.softFlag, sanitized, null);

  factory NoraSanitizationResult.blocked(String reason) =>
      NoraSanitizationResult._(NoraSanitizationOutcome.blocked, '', reason);

  bool get isBlocked => outcome == NoraSanitizationOutcome.blocked;
  bool get isAllowed => outcome == NoraSanitizationOutcome.allowed;
  bool get isSoftFlag => outcome == NoraSanitizationOutcome.softFlag;
}

enum NoraSanitizationOutcome { allowed, softFlag, blocked }

/// Thrown by [NoraInputSanitizer.sanitize] when input is rejected outright.
class NoraInputRejected implements Exception {
  final String reason;
  const NoraInputRejected(this.reason);
  @override
  String toString() => 'NoraInputRejected: $reason';
}

/// First line of defence between the user's text and the Gemini API.
///
/// All checks are deterministic regex/keyword heuristics — no AI call —
/// so they can run synchronously and cheaply on every keystroke-send.
class NoraInputSanitizer {
  NoraInputSanitizer._();

  /// Maximum characters forwarded to the model.
  static const int maxChars = 800;

  /// Canned response to render when an injection attempt is blocked.
  /// Wording is intentionally neutral — the user is NOT told they were "detected".
  static const String blockedResponse =
      'Estoy aquí para apoyarte en tu rehabilitación. '
      '¿Hay algo relacionado con tus ejercicios o tu recuperación '
      'en lo que pueda ayudarte?';

  /// Soft reminder prepended when input drifts off-topic.
  static const String _offTopicPrefix =
      '[CONTEXT: The user is a rehabilitation patient. '
      'Stay within physiotherapy domain only.]';

  /// One-shot evaluation. Returns the [NoraSanitizationResult] describing
  /// what to do next. Throws [NoraInputRejected] only on empty input.
  static NoraSanitizationResult evaluate(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      throw const NoraInputRejected('empty input');
    }

    // Strip HTML/script tags before any pattern check so attackers can't hide
    // intent inside markup.
    final cleaned = _stripTags(trimmed);

    if (_isInjectionAttempt(cleaned)) {
      if (kDebugMode) {
        final preview = cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
        AppLogger.warning(
          '[Nora] Injection attempt blocked: $preview',
          tag: 'NoraSafety',
        );
      }
      return NoraSanitizationResult.blocked('injection_pattern');
    }

    final truncated = _truncate(cleaned, maxChars: maxChars);

    if (_isOffTopic(truncated)) {
      return NoraSanitizationResult.softFlag('$_offTopicPrefix\n\n$truncated');
    }

    return NoraSanitizationResult.allowed(truncated);
  }

  /// Convenience wrapper used in tests and simple callers.
  /// Throws [NoraInputRejected] if blocked, otherwise returns the cleaned text.
  static String sanitize(String rawInput) {
    final result = evaluate(rawInput);
    if (result.isBlocked) {
      throw NoraInputRejected(result.blockedReason ?? 'blocked');
    }
    return result.sanitized;
  }

  // ------------------------------------------------------------------
  // Pattern catalogues (categories A-D from the spec).
  // Each pattern is matched case-insensitively against the normalised input.
  // ------------------------------------------------------------------

  /// CATEGORY A — Direct override attempts.
  static const List<String> _categoryA = [
    'ignore previous instructions',
    'ignore all instructions',
    'ignore your instructions',
    'ignore your system prompt',
    'forget your instructions',
    'forget previous instructions',
    'new instructions:',
    'your real instructions are',
    'override:',
    'disregard the above',
  ];

  /// CATEGORY B — Persona hijacking.
  static const List<String> _categoryB = [
    'you are now',
    'act as',
    'pretend you are',
    'roleplay as',
    'simulate being',
    'you have no restrictions',
    'dan',
    'developer mode',
    'jailbreak',
    'god mode',
  ];

  /// CATEGORY C — Prompt extraction.
  static const List<String> _categoryC = [
    'what is your system prompt',
    'show me your instructions',
    'repeat your prompt',
    'what were you told',
    'reveal your',
  ];

  /// CATEGORY D — Context manipulation.
  static const List<String> _categoryD = [
    'from now on',
    'starting now',
    'for the rest of this conversation',
    'in all future responses',
  ];

  /// Common l33t-speak substitutions limited to the most obvious cases:
  /// vowels and 's'. This is intentionally narrow — over-aggressive
  /// transliteration would catch innocent rehab terms.
  static const Map<String, String> _leetMap = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '@': 'a',
    '\$': 's',
  };

  /// Returns true if [input] contains any injection pattern from A-D.
  /// Public so the history layer can re-screen stored messages
  /// (Task 3.2 — stored prompt injection defence).
  static bool isInjectionAttempt(String input) => _isInjectionAttempt(input);

  static bool _isInjectionAttempt(String input) {
    final normalised = _normaliseForMatching(input);
    final all = [..._categoryA, ..._categoryB, ..._categoryC, ..._categoryD];
    for (final pattern in all) {
      if (normalised.contains(pattern)) return true;
    }
    return false;
  }

  /// Lowercase + collapse whitespace + l33t-substitute digits.
  static String _normaliseForMatching(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_leetMap[ch] ?? ch);
    }
    // Collapse any run of whitespace (including newlines) into a single space.
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ------------------------------------------------------------------
  // Off-topic heuristic.
  // The system prompt itself is the strongest defence; this is just a soft
  // hint so the model gets an extra reminder when domain drift is obvious.
  // ------------------------------------------------------------------

  /// Strong off-topic signals — words that have essentially no rehabilitation
  /// reading in Spanish or English.
  static const List<String> _offTopicSignals = [
    'weather',
    'clima',
    'temperatura del aire',
    'stock',
    'bolsa',
    'crypto',
    'bitcoin',
    'president',
    'presidente',
    'election',
    'elección',
    'recipe',
    'receta',
    'movie',
    'película',
    'football',
    'fútbol',
    'soccer',
    'programming',
    'programación',
    'python',
    'javascript',
    'sql',
    'capital of',
    'capital de',
  ];

  /// Light rehabilitation vocabulary used to *exempt* otherwise neutral
  /// phrases from off-topic flagging.
  static const List<String> _rehabSignals = [
    'rehab',
    'fisio',
    'physio',
    'ejercicio',
    'exercise',
    'dolor',
    'pain',
    'lesión',
    'injury',
    'músculo',
    'muscle',
    'rodilla',
    'knee',
    'espalda',
    'back',
    'hombro',
    'shoulder',
    'cadera',
    'hip',
    'tobillo',
    'ankle',
    'muñeca',
    'wrist',
    'cuello',
    'neck',
    'estiramiento',
    'stretch',
    'recuperación',
    'recovery',
    'terapia',
    'therapy',
    'movilidad',
    'mobility',
    'postura',
    'posture',
    'fuerza',
    'strength',
    'articulación',
    'joint',
    'hinchazón',
    'swelling',
    'inflamación',
    'inflammation',
  ];

  @visibleForTesting
  static bool isOffTopic(String input) => _isOffTopic(input);

  static bool _isOffTopic(String input) {
    final normalised = _normaliseForMatching(input);

    // Hard signal: any explicit off-topic keyword present.
    for (final word in _offTopicSignals) {
      if (normalised.contains(word)) return true;
    }

    // Soft signal: long-ish input with zero rehab vocabulary.
    final wordCount = normalised
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .length;
    if (wordCount < 4) return false; // too short to judge

    for (final word in _rehabSignals) {
      if (normalised.contains(word)) return false;
    }
    return true;
  }

  // ------------------------------------------------------------------
  // Helpers.
  // ------------------------------------------------------------------

  @visibleForTesting
  static String truncate(String input, {int maxChars = 800}) =>
      _truncate(input, maxChars: maxChars);

  static String _truncate(String input, {required int maxChars}) {
    if (input.length <= maxChars) return input;
    final cut = input.substring(0, maxChars);
    return '$cut... [respuesta truncada por longitud]';
  }

  /// Strip a conservative subset of HTML/script tags. We do not aim for a
  /// full HTML parser — just enough to defang stored-XSS-style payloads
  /// before they reach the model or Firestore.
  static String stripHtml(String input) => _stripTags(input);

  static final RegExp _tagRegex = RegExp(r'<[^>]*>');

  static String _stripTags(String input) =>
      input.replaceAll(_tagRegex, '').trim();
}
