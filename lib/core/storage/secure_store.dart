import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Small secrets (Hive encryption key, API tokens) in the platform keystore:
/// Android Keystore, iOS Keychain, WebCrypto on the web.
class SecureStore {
  SecureStore._();
  static final instance = SecureStore._();

  static const _hiveKey = 'tf_hive_key';
  static const _accessToken = 'tf_access_token';
  static const _refreshToken = 'tf_refresh_token';

  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  // Fallback used only if the platform keystore is unavailable (some
  // desktop/CI environments). Data is still encrypted, the key is not.
  Box? _fallback;

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStore: keystore unavailable ($e), using fallback');
      _fallback ??= await Hive.openBox('tf_keystore_fallback');
      return _fallback!.get(key) as String?;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (_) {
      _fallback ??= await Hive.openBox('tf_keystore_fallback');
      value == null ? await _fallback!.delete(key) : await _fallback!.put(key, value);
    }
  }

  Future<List<int>> hiveEncryptionKey() async {
    final existing = await _read(_hiveKey);
    if (existing != null) return base64Url.decode(existing);
    final key = Hive.generateSecureKey();
    await _write(_hiveKey, base64Url.encode(key));
    return key;
  }

  Future<String?> accessToken() => _read(_accessToken);
  Future<String?> refreshToken() => _read(_refreshToken);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _write(_accessToken, access);
    if (refresh != null) await _write(_refreshToken, refresh);
  }

  Future<void> clearTokens() async {
    await _write(_accessToken, null);
    await _write(_refreshToken, null);
  }
}
