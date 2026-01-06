import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local data source for SharedPreferences operations
class LocalDataSource {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ Generic operations ============

  Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final p = await prefs;
    return p.getBool(key);
  }

  Future<void> setDouble(String key, double value) async {
    final p = await prefs;
    await p.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final p = await prefs;
    return p.getDouble(key);
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final p = await prefs;
    final jsonString = p.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }

  Future<bool> containsKey(String key) async {
    final p = await prefs;
    return p.containsKey(key);
  }

  // ============ Specific operations ============

  Future<void> setThemeMode(int modeIndex) async {
    await setInt('themeMode', modeIndex);
  }

  Future<int> getThemeMode() async {
    return await getInt('themeMode') ?? 0;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await setBool('onboardingComplete', complete);
  }

  Future<bool> isOnboardingComplete() async {
    return await getBool('onboardingComplete') ?? false;
  }

  Future<void> setFcmToken(String token) async {
    await setString('fcmToken', token);
  }

  Future<String?> getFcmToken() async {
    return await getString('fcmToken');
  }
}
