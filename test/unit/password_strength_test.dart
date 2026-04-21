import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/core/utils/password_strength.dart';

void main() {
  group('PasswordStrengthCheck.of', () {
    test('empty string -> empty', () {
      expect(PasswordStrengthCheck.of(''), PasswordStrength.empty);
    });

    test('single character -> weak', () {
      expect(PasswordStrengthCheck.of('a'), PasswordStrength.weak);
    });

    test('seven characters -> weak (below 8-char bar)', () {
      expect(PasswordStrengthCheck.of('abcdefg'), PasswordStrength.weak);
    });

    test('eight lowercase only -> weak (one class)', () {
      expect(PasswordStrengthCheck.of('abcdefgh'), PasswordStrength.weak);
    });

    test('eight uppercase only -> weak (one class)', () {
      expect(PasswordStrengthCheck.of('ABCDEFGH'), PasswordStrength.weak);
    });

    test('eight digits only -> weak (one class)', () {
      expect(PasswordStrengthCheck.of('12345678'), PasswordStrength.weak);
    });

    test('eight symbols only -> weak (one class)', () {
      expect(PasswordStrengthCheck.of(r'!@#$%^&*'), PasswordStrength.weak);
    });

    test('lowercase + uppercase -> medium (two classes)', () {
      expect(PasswordStrengthCheck.of('AbcDefgh'), PasswordStrength.medium);
    });

    test('lowercase + digits -> medium (two classes)', () {
      expect(PasswordStrengthCheck.of('abcd1234'), PasswordStrength.medium);
    });

    test('lowercase + upper + digit -> strong (three classes)', () {
      expect(PasswordStrengthCheck.of('Abcdef12'), PasswordStrength.strong);
    });

    test('all four classes -> strong', () {
      expect(PasswordStrengthCheck.of(r'Abcd12!@'), PasswordStrength.strong);
    });

    test('very long single-class password still weak', () {
      expect(
        PasswordStrengthCheck.of('aaaaaaaaaaaaaaaaaaaa'),
        PasswordStrength.weak,
      );
    });

    test('isAcceptable is false for empty', () {
      expect(PasswordStrengthCheck.isAcceptable(''), isFalse);
    });

    test('isAcceptable is false for weak', () {
      expect(PasswordStrengthCheck.isAcceptable('abcdefgh'), isFalse);
    });

    test('isAcceptable is true for medium', () {
      expect(PasswordStrengthCheck.isAcceptable('Abcdefgh'), isTrue);
    });

    test('isAcceptable is true for strong', () {
      expect(PasswordStrengthCheck.isAcceptable(r'Abcd12!@'), isTrue);
    });
  });

  group('PasswordStrengthMeta', () {
    test('fill values monotonically increase', () {
      expect(PasswordStrength.empty.fill, 0.0);
      expect(PasswordStrength.weak.fill, lessThan(PasswordStrength.medium.fill));
      expect(
        PasswordStrength.medium.fill,
        lessThan(PasswordStrength.strong.fill),
      );
      expect(PasswordStrength.strong.fill, 1.0);
    });

    test('labels match UI contract', () {
      expect(PasswordStrength.empty.label, '');
      expect(PasswordStrength.weak.label, 'Weak');
      expect(PasswordStrength.medium.label, 'Medium');
      expect(PasswordStrength.strong.label, 'Strong');
    });
  });
}
