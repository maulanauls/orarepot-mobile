import 'api_client.dart';
import 'auth_store.dart';
import 'models/biller_models.dart';

/// Mirrors orappob `lib/store-auth.ts` enter/login/register/me/logout.
class AuthRepository {
  AuthRepository(this._api, this._store);

  final ApiClient _api;
  final AuthStore _store;

  AuthStore get store => _store;

  Future<StoreAuth> login({
    required String identifier,
    required String password,
    bool remember = true,
  }) async {
    final body = await _api.postJson(
      '/biller/auth/login',
      body: {
        'identifier': identifier.trim(),
        'password': password,
      },
    );
    if (body['otp_required'] == true) {
      throw OtpRequiredException(OtpChallenge.fromJson(body));
    }
    final auth = StoreAuth.fromJson(body);
    await _store.persist(auth, remember: remember);
    return auth;
  }

  /// Same contract as orappob `loginWithGoogle(code)` → `POST /biller/auth/google`.
  /// Throws [GooglePhoneRequiredException] when the Google account has no WhatsApp number.
  Future<StoreAuth> loginWithGoogle({
    required String code,
    bool remember = true,
  }) async {
    final body = await _api.postJson(
      '/biller/auth/google',
      body: {'code': code.trim()},
    );
    if (body['phone_required'] == true) {
      throw GooglePhoneRequiredException(GooglePhoneRequired.fromJson(body));
    }
    if (body['otp_required'] == true) {
      throw OtpRequiredException(OtpChallenge.fromJson(body));
    }
    final auth = StoreAuth.fromJson(body);
    await _store.persist(auth, remember: remember);
    return auth;
  }

  /// Bind WhatsApp after Google when [GooglePhoneRequiredException] was thrown.
  Future<OtpChallenge> bindGooglePhone({
    required String pending,
    required String phone,
  }) async {
    final body = await _api.postJson(
      '/biller/auth/google/phone',
      body: {
        'pending': pending.trim(),
        'phone': phone.trim(),
      },
    );
    if (body['otp_required'] != true) {
      throw ApiException('Respons OTP tidak valid.');
    }
    return OtpChallenge.fromJson(body);
  }

  Future<StoreAuth> register({
    String fullName = '',
    required String identifier,
    required String password,
  }) async {
    final split = splitIdentifier(identifier);
    final body = await _api.postJson(
      '/biller/auth/register',
      body: {
        'full_name': fullName.trim(),
        'identifier': identifier.trim(),
        'email': split.email,
        'phone': split.phone,
        'password': password,
      },
    );
    if (body['otp_required'] == true) {
      throw OtpRequiredException(OtpChallenge.fromJson(body));
    }
    final auth = StoreAuth.fromJson(body);
    await _store.persist(auth, remember: true);
    return auth;
  }

  Future<StoreAuth> enter({
    String email = '',
    String phone = '',
    required String password,
    bool remember = true,
  }) async {
    final body = await _api.postJson(
      '/biller/auth/enter',
      body: {
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );
    if (body['otp_required'] == true) {
      throw OtpRequiredException(OtpChallenge.fromJson(body));
    }
    final auth = StoreAuth.fromJson(body);
    await _store.persist(auth, remember: remember);
    return auth;
  }

  /// Completes an OTP challenge from [enter] via `POST /biller/auth/enter/verify`.
  Future<StoreAuth> verifyEnterOtp({
    required String challenge,
    required String code,
    bool remember = true,
  }) async {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (challenge.trim().isEmpty || digits.length != 6) {
      throw ApiException('Kode harus tepat 6 angka.');
    }
    final body = await _api.postJson(
      '/biller/auth/enter/verify',
      body: {
        'challenge': challenge.trim(),
        'code': digits,
      },
    );
    final auth = StoreAuth.fromJson(body);
    await _store.persist(auth, remember: remember);
    return auth;
  }

  Future<BillerUser?> fetchMe() async {
    final token = _store.token;
    if (token == null) return null;
    try {
      final body = await _api.getJson('/biller/auth/me', auth: true);
      return BillerUser.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (_store.token != null) {
        await _api.postJson('/biller/auth/logout', auth: true);
      }
    } catch (_) {
      // ignore network logout failures
    }
    await _store.clear();
  }

  static ({String email, String phone}) splitIdentifier(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return (email: '', phone: '');
    if (value.contains('@')) return (email: value.toLowerCase(), phone: '');
    return (email: '', phone: value);
  }
}
