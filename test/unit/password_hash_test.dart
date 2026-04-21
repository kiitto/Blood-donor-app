import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/core/utils/password_hash.dart';

void main() {
  group('PasswordHash.hash', () {
    test('same password + same salt -> deterministic hash', () {
      final a = PasswordHash.hash('hunter2', 'salt-123');
      final b = PasswordHash.hash('hunter2', 'salt-123');
      expect(a, b);
    });

    test('same password + different salts -> different hashes', () {
      final a = PasswordHash.hash('hunter2', 'salt-A');
      final b = PasswordHash.hash('hunter2', 'salt-B');
      expect(a, isNot(b));
    });

    test('different passwords + same salt -> different hashes', () {
      final a = PasswordHash.hash('hunter2', 'salt');
      final b = PasswordHash.hash('hunter3', 'salt');
      expect(a, isNot(b));
    });

    test('output is hex sha256 (64 chars)', () {
      final h = PasswordHash.hash('whatever', 'salt');
      expect(h.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h), isTrue);
    });
  });

  group('PasswordHash.verify', () {
    test('correct password -> true', () {
      final salt = PasswordHash.newSalt();
      final stored = PasswordHash.hash('correct horse', salt);
      expect(
        PasswordHash.verify(
          password: 'correct horse',
          salt: salt,
          expectedHash: stored,
        ),
        isTrue,
      );
    });

    test('wrong password -> false', () {
      final salt = PasswordHash.newSalt();
      final stored = PasswordHash.hash('correct horse', salt);
      expect(
        PasswordHash.verify(
          password: 'wrong horse',
          salt: salt,
          expectedHash: stored,
        ),
        isFalse,
      );
    });
  });

  group('PasswordHash.newSalt', () {
    test('two generated salts are (almost certainly) different', () {
      final a = PasswordHash.newSalt();
      final b = PasswordHash.newSalt();
      expect(a, isNot(b));
      expect(a, isNotEmpty);
    });
  });
}
