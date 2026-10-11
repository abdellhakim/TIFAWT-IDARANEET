import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/secure_store.dart';

/// Backend location, injected at build time:
///   flutter run --dart-define=TIFAWT_API_URL=http://10.0.2.2:5000
/// Without it the app runs fully standalone and sync uses a simulated server.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('TIFAWT_API_URL');
  static bool get enabled => baseUrl.isNotEmpty;
}

class ApiException implements Exception {
  const ApiException(this.status, this.message);
  final int status;
  final String message;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Thin JSON client for the Flask REST API. Adds the JWT and refreshes it
/// once on a 401.
class ApiClient {
  ApiClient(this.baseUrl, {http.Client? client, SecureStore? tokens})
    : _http = client ?? http.Client(),
      _tokens = tokens ?? SecureStore.instance;

  final String baseUrl;
  final http.Client _http;
  final SecureStore _tokens;

  static const _timeout = Duration(seconds: 12);

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) => _send('GET', path, auth: auth);

  Future<Map<String, dynamic>> post(String path, Object body, {bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> put(String path, Object body) => _send('PUT', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool retried = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokens.accessToken();
      if (token == null) throw const ApiException(401, 'not authenticated');
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _http.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 401 && auth && !retried && await _refresh()) {
      return _send(method, path, body: body, auth: auth, retried: true);
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, (decoded['error'] ?? response.reasonPhrase ?? '').toString());
    }
    return decoded;
  }

  Future<bool> _refresh() async {
    final refresh = await _tokens.refreshToken();
    if (refresh == null) return false;
    try {
      final response = await _http
          .post(Uri.parse('$baseUrl/api/auth/refresh'), headers: {'Authorization': 'Bearer $refresh'})
          .timeout(_timeout);
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await _tokens.saveTokens(access: json['access_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stores tokens returned by /api/auth/login or /register.
  Future<void> storeSession(Map<String, dynamic> json) =>
      _tokens.saveTokens(access: json['access_token'] as String, refresh: json['refresh_token'] as String?);
}
