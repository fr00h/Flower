import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../repositories/auth_api.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kToken = 'auth_token';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _token;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null;
  bool get isStaff => _user?.isStaff ?? false;

  bool isRole(Role role) => _user?.role == role;

  Future<void> restore() async {
    final token = _prefs.getString(_kToken);
    if (token == null) return;

    _token = token;
    try {
      await _apply(await _api.refresh());
    } on ApiException {
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    await _apply(await _api.login(email, password));
  }

  Future<void> register(String email, String password, String name) async {
    await _api.register(email, password, name);
    await login(email, password);
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _prefs.remove(_kToken);
    notifyListeners();
  }

  Future<void> _apply(AuthResult result) async {
    _token = result.token;
    _user = result.user;
    await _prefs.setString(_kToken, result.token);
    notifyListeners();
  }
}
