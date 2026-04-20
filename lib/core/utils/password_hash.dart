import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Review-1 grade: SHA-256 with a per-user random salt.
/// Not password-hashing-scheme production-grade; good enough for local-only demo.
class PasswordHash {
  PasswordHash._();

  static String newSalt([int length = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) =>
      hash(password, salt) == expectedHash;
}
