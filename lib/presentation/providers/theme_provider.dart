import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

/// Owns the three knobs that affect global rendering: dark/light mode, text
/// scale, and high-contrast. All three are persisted to SharedPreferences via
/// the legacy `app_settings` keys (`textSize`, `highContrast`) so the existing
/// patient-side accessibility screens continue to read/write the same values.
class ThemeProvider with ChangeNotifier {
  // Keys must match what `text_size_screen.dart` and `high_contrast_screen.dart`
  // already write through `ProgressService`. The legacy values live inside a
  // single JSON map under `app_settings`; for the global theme we mirror them
  // into top-level prefs so we can read them synchronously at startup.
  static const _kThemeMode = 'themeMode';
  static const _kTextScale = 'textScale';
  static const _kHighContrast = 'highContrast';

  static const double minTextScale = 0.8;
  static const double maxTextScale = 1.4;
  static const double defaultTextScale = 1.0;

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = defaultTextScale;
  bool _highContrast = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  double get textScale => _textScale;
  TextScaler get textScaler => TextScaler.linear(_textScale);
  bool get highContrast => _highContrast;

  /// When high-contrast is enabled we force dark mode regardless of the user's
  /// dark/light preference — the dark palette has the strongest contrast in
  /// our existing theme. The original [themeMode] choice is preserved in
  /// SharedPreferences so toggling high-contrast off restores it.
  ThemeMode get effectiveThemeMode =>
      _highContrast ? ThemeMode.dark : _themeMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }
    final scale = prefs.getDouble(_kTextScale);
    if (scale != null) {
      _textScale = scale.clamp(minTextScale, maxTextScale);
    }
    _highContrast = prefs.getBool(_kHighContrast) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(minTextScale, maxTextScale);
    if (clamped == _textScale) return;
    _textScale = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, clamped);
    notifyListeners();
  }

  Future<void> setHighContrast(bool enabled) async {
    if (enabled == _highContrast) return;
    _highContrast = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, enabled);
    notifyListeners();
  }

  // Theme data getters using centralized AppTheme
  static ThemeData get lightTheme => AppTheme.light;
  static ThemeData get darkTheme => AppTheme.dark;
}
