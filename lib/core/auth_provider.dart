import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

/// Menyimpan sesi (token + profil) dan menjadi satu-satunya pemilik [ApiClient].
class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api) {
    api.onUnauthorized = _expire;
  }

  final ApiClient api;
  AppUser? user;
  bool ready = false;

  bool get loggedIn => user != null;

  /// Memulihkan sesi dari penyimpanan lokal saat aplikasi dibuka.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString('token');
    if (api.token != null) {
      try {
        user = AppUser.fromJson(await api.get('auth/me/') as Map<String, dynamic>);
      } on ApiException catch (e) {
        if (e.unauthorized) await _clear(prefs);
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final res = await api.post('auth/login/', {'username': username, 'password': password})
        as Map<String, dynamic>;
    await _startSession(res);
  }

  Future<void> register(Map<String, dynamic> body) async {
    final res = await api.post('auth/register/', body) as Map<String, dynamic>;
    await _startSession(res);
  }

  Future<void> _startSession(Map<String, dynamic> res) async {
    api.token = res['token'] as String;
    user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    (await SharedPreferences.getInstance()).setString('token', api.token!);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = AppUser.fromJson(await api.get('auth/me/') as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    user = AppUser.fromJson(await api.patch('auth/me/', body) as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> changePassword(String old, String next) async {
    final res = await api.post('auth/password/',
        {'old_password': old, 'new_password1': next, 'new_password2': next}) as Map<String, dynamic>;
    api.token = res['token'] as String; // token lama dicabut server
    (await SharedPreferences.getInstance()).setString('token', api.token!);
  }

  Future<void> logout() async {
    try {
      await api.post('auth/logout/');
    } on ApiException {
      // tetap keluar secara lokal walau server tidak terjangkau
    }
    await _clear(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> _expire() async {
    await _clear(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> _clear(SharedPreferences prefs) async {
    api.token = null;
    user = null;
    await prefs.remove('token');
  }
}
