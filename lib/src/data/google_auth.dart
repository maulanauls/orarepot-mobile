import 'package:google_sign_in/google_sign_in.dart';

import '../../app_config.dart';

/// Mirrors orappob `lib/google-auth.ts`: obtain an OAuth authorization code
/// that `/biller/auth/google` can exchange server-side.
class GoogleAuth {
  GoogleAuth(this._config);

  final AppConfig _config;

  GoogleSignIn get _client => GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
        serverClientId: _config.googleClientId,
      );

  /// Returns the server auth code (same payload web sends as `{ code }`).
  Future<String> requestCode() async {
    if (_config.googleClientId.trim().isEmpty) {
      throw StateError('Google client ID is not set');
    }

    final client = _client;
    // Clear any stale session so we always get a fresh server auth code.
    await client.signOut();

    final account = await client.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled');
    }

    final code = account.serverAuthCode?.trim() ?? '';
    if (code.isEmpty) {
      throw StateError(
        'Google tidak mengembalikan auth code. '
        'Pastikan Android OAuth client (package + SHA-1) sudah dibuat '
        'di Google Cloud project yang sama dengan web client ID.',
      );
    }
    return code;
  }
}
