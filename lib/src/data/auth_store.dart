import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/biller_models.dart';

/// Persistent customer session — same role as orappob `orappob-customer` storage.
class AuthStore {
  AuthStore();

  static const _key = 'orarepot-customer';

  StoreAuth? _auth;
  bool _loaded = false;

  StoreAuth? get auth => _auth;
  String? get token => _auth?.token;
  BillerUser? get user => _auth?.user;
  bool get isSignedIn => _auth?.token.isNotEmpty == true;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _loaded = true;
    if (raw == null || raw.isEmpty) {
      _auth = null;
      return;
    }
    try {
      final parsed = StoreAuth.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (parsed.token.isEmpty || parsed.user.usersIdf.isEmpty) {
        _auth = null;
        return;
      }
      _auth = parsed;
    } catch (_) {
      _auth = null;
    }
  }

  /// When [remember] is false, keep the session in memory only (like sessionStorage).
  Future<void> persist(StoreAuth auth, {bool remember = true}) async {
    _auth = auth;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_key, jsonEncode(auth.toJson()));
    } else {
      await prefs.remove(_key);
    }
  }

  Future<void> clear() async {
    _auth = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
