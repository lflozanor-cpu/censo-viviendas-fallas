import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  static const _keyBaseUrl = 'server_base_url';
  static const _keyViviendas = 'viviendas_pending';
  static const _keyFotos = 'fotos_pending';

  static Future<void> saveBaseUrl(String url) async {
    await _prefs?.setString(_keyBaseUrl, url);
  }

  static Future<String?> getBaseUrl() async {
    return _prefs?.getString(_keyBaseUrl);
  }

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    return _prefs?.getString(_keyToken);
  }

  static Future<void> saveEmail(String email) async {
    await _prefs?.setString(_keyEmail, email);
  }

  static Future<String?> getEmail() async {
    return _prefs?.getString(_keyEmail);
  }

  static Future<void> clearAuth() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyEmail);
  }

  static Future<void> savePendingViviendas(List<Map<String, dynamic>> list) async {
    await _prefs?.setString(_keyViviendas, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getPendingViviendas() async {
    final s = _prefs?.getString(_keyViviendas);
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> savePendingFotos(List<Map<String, dynamic>> list) async {
    await _prefs?.setString(_keyFotos, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getPendingFotos() async {
    final s = _prefs?.getString(_keyFotos);
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
