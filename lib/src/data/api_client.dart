import 'dart:convert';

import 'package:alice_http/alice_http_adapter.dart';
import 'package:alice_http/alice_http_extensions.dart';
import 'package:http/http.dart' as http;

import '../../app_config.dart';
import 'auth_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthRequiredException extends ApiException {
  AuthRequiredException() : super('Sesi habis. Masuk lagi untuk melanjutkan.');
}

/// Thin HTTP client mirroring orappob `fetch(`${apiBase()}/biller/...`)`.
class ApiClient {
  ApiClient({
    required this.config,
    required this.authStore,
    http.Client? httpClient,
    AliceHttpAdapter? aliceAdapter,
  })  : _http = httpClient ?? http.Client(),
        _alice = aliceAdapter;

  final AppConfig config;
  final AuthStore authStore;
  final http.Client _http;
  final AliceHttpAdapter? _alice;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = config.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<http.Response> _execute(
    String method,
    Uri uri,
    Map<String, String> headers, {
    Map<String, dynamic>? body,
  }) {
    final encoded = body == null ? null : jsonEncode(body);
    final future = switch (method) {
      'POST' => _http.post(uri, headers: headers, body: encoded),
      _ => _http.get(uri, headers: headers),
    };
    final alice = _alice;
    if (alice == null) return future;
    return future.interceptWithAlice(alice, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    final headers = <String, String>{
      if (body != null) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = authStore.token;
      if (token == null || token.isEmpty) throw AuthRequiredException();
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    final uri = _uri(path, query);
    try {
      response = await _execute(method, uri, headers, body: body);
    } on http.ClientException catch (e) {
      final detail = e.message.toLowerCase();
      if (detail.contains('certificate') ||
          detail.contains('handshake') ||
          detail.contains('ssl') ||
          detail.contains('tls')) {
        throw ApiException(
          'Koneksi HTTPS gagal (sertifikat tidak cocok untuk ${uri.host}). '
          'Periksa API_BASE_URL.',
        );
      }
      throw ApiException('Layanan belum hidup. Coba lagi sebentar.');
    } catch (e) {
      if (e is ApiException) rethrow;
      final detail = '$e'.toLowerCase();
      if (detail.contains('certificate') ||
          detail.contains('handshake') ||
          detail.contains('certificate_verify_failed') ||
          detail.contains('ssl') ||
          detail.contains('tls')) {
        throw ApiException(
          'Koneksi HTTPS gagal (sertifikat tidak cocok untuk ${uri.host}). '
          'Periksa API_BASE_URL.',
        );
      }
      throw ApiException('Layanan belum hidup. Coba lagi sebentar.');
    }

    if (response.statusCode == 401 && auth) {
      await authStore.clear();
      throw AuthRequiredException();
    }

    final raw = response.body;
    final looksLikeHtml = raw.trimLeft().toLowerCase().startsWith('<!doctype') ||
        raw.trimLeft().toLowerCase().startsWith('<html') ||
        raw.contains('Checking your browser');

    Map<String, dynamic> payload = {};
    var jsonOk = false;
    if (raw.isNotEmpty && !looksLikeHtml) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
          jsonOk = true;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
          jsonOk = true;
        }
      } catch (_) {
        jsonOk = false;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      throw ApiException(
        error is String ? error : 'Permintaan gagal',
        statusCode: response.statusCode,
      );
    }

    // Cloudflare / edge HTML often returns HTTP 200 — treat as transport failure.
    if (looksLikeHtml || (raw.isNotEmpty && !jsonOk)) {
      throw ApiException(
        'Layanan belum hidup. Coba lagi sebentar.',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}
