import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/authentication/password_hasher.dart';
import '../../../core/storage/local_store.dart';
import '../../../shared/models/app_user.dart';

enum AuthError { wrongCredentials, accountExists }

class AuthException implements Exception {
  const AuthException(this.error);
  final AuthError error;
}

/// Phone numbers and e-mails are both accepted as login identifiers.
abstract final class Identifier {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$');
  static final _phone = RegExp(r'^(\+212|0)[5-7]\d{8}$');

  static String normalize(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('@')) return value;
    return value.replaceAll(RegExp(r'[\s.\-]'), '');
  }

  static bool isEmail(String raw) => _email.hasMatch(normalize(raw));
  static bool isValid(String raw) {
    final value = normalize(raw);
    return _email.hasMatch(value) || _phone.hasMatch(value);
  }
}

/// Offline-first accounts: credentials are verified on the device
/// (PBKDF2 hash in an encrypted box), so login works without network.
/// The same account is mirrored to the API by the auth controller.
class AuthRepository {
  static const _uuid = Uuid();
  Box get _box => LocalStore.box(Boxes.auth);

  AppUser? currentUser() {
    final id = _box.get('session') as String?;
    return id == null ? null : _userById(id);
  }

  AppUser? _userById(String id) {
    final raw = _box.get('user:$id');
    return raw == null ? null : AppUser.fromJson(raw as Map);
  }

  bool isDemo(String userId) => ((_box.get('user:$userId') as Map?)?['demo'] as bool?) ?? false;

  Future<AppUser> login(String identifier, String password) async {
    final id = _box.get('login:${Identifier.normalize(identifier)}') as String?;
    final record = id == null ? null : _box.get('user:$id') as Map?;
    if (record == null ||
        !PasswordHasher.verify(password, record['salt'] as String, record['hash'] as String)) {
      throw const AuthException(AuthError.wrongCredentials);
    }
    await _box.put('session', id);
    return AppUser.fromJson(record);
  }

  Future<AppUser> register({
    required String name,
    required String identifier,
    required String password,
  }) async {
    final key = Identifier.normalize(identifier);
    if (_box.containsKey('login:$key')) {
      throw const AuthException(AuthError.accountExists);
    }
    final isEmail = Identifier.isEmail(key);
    final user = AppUser(
      id: _uuid.v4(),
      name: name.trim(),
      phone: isEmail ? null : key,
      email: isEmail ? key : null,
    );
    final salt = PasswordHasher.newSalt();
    await _box.put('user:${user.id}', {
      ...user.toJson(),
      'salt': salt,
      'hash': PasswordHasher.hash(password, salt),
    });
    await _box.put('login:$key', user.id);
    await _box.put('session', user.id);
    return user;
  }

  Future<void> logout() => _box.delete('session');

  Future<void> deleteAccount(String userId) async {
    for (final key in _box.keys.toList()) {
      if (key is String && key.startsWith('login:') && _box.get(key) == userId) {
        await _box.delete(key);
      }
    }
    await _box.delete('user:$userId');
    await _box.delete('session');
    await LocalStore.wipeUser(userId);
  }
}
