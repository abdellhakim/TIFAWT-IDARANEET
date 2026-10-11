import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256, so offline accounts never keep a password in clear.
abstract final class PasswordHasher {
  static const iterations = 4000;

  static String newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String hash(String password, String salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final block = Uint8List.fromList([...utf8.encode(salt), 0, 0, 0, 1]);

    var u = hmac.convert(block).bytes;
    final result = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return base64Url.encode(result);
  }

  static bool verify(String password, String salt, String expected) {
    final actual = hash(password, salt);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }
}
