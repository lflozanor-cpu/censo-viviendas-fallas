import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../storage/local_storage.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._api);
  final ApiService _api;
  String? _token;
  String? _email;

  String? get token => _token;
  String? get email => _email;
  bool get isLoggedIn => _token != null;

  Future<void> loadStored() async {
    _token = await LocalStorage.getToken();
    _email = await LocalStorage.getEmail();
    _api.setToken(_token);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final data = await _api.login(email, password);
    if (data == null) return false;
    _token = data['access_token'] as String?;
    _email = (data['user'] as Map<String, dynamic>?)?['email'] as String?;
    _api.setToken(_token);
    if (_token != null) {
      await LocalStorage.saveToken(_token!);
      await LocalStorage.saveEmail(_email ?? email);
    }
    notifyListeners();
    return _token != null;
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
    _api.setToken(null);
    await LocalStorage.clearAuth();
    notifyListeners();
  }
}
