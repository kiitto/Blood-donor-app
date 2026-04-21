import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('null -> required error', () {
      expect(Validators.email(null), 'Email is required');
    });

    test('empty -> required error', () {
      expect(Validators.email('   '), 'Email is required');
    });

    test('no @ -> invalid', () {
      expect(Validators.email('plainaddress'), 'Enter a valid email');
    });

    test('missing TLD -> invalid', () {
      expect(Validators.email('user@host'), 'Enter a valid email');
    });

    test('valid address -> null', () {
      expect(Validators.email('donor@example.com'), isNull);
    });

    test('valid address with plus sign -> null', () {
      expect(Validators.email('donor+tag@example.co.in'), isNull);
    });
  });

  group('Validators.phone', () {
    test('null -> required', () {
      expect(Validators.phone(null), 'Phone is required');
    });

    test('empty -> required', () {
      expect(Validators.phone(''), 'Phone is required');
    });

    test('9 digits -> invalid', () {
      expect(Validators.phone('987654321'), 'Enter a 10-digit mobile number');
    });

    test('11 digits -> invalid', () {
      expect(Validators.phone('98765432100'), 'Enter a 10-digit mobile number');
    });

    test('starting with 5 -> invalid', () {
      expect(Validators.phone('5876543210'), 'Enter a 10-digit mobile number');
    });

    test('starting with 6 -> valid', () {
      expect(Validators.phone('6000000000'), isNull);
    });

    test('starting with 9 -> valid', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('with spaces -> still valid after strip', () {
      expect(Validators.phone('98765 43210'), isNull);
    });
  });

  group('Validators.name', () {
    test('null -> required', () {
      expect(Validators.name(null), 'Name is required');
    });

    test('single letter -> too short', () {
      expect(Validators.name('A'), 'Too short');
    });

    test('contains digits -> letters only', () {
      expect(Validators.name('Anita42'), 'Letters only');
    });

    test('plain letters -> valid', () {
      expect(Validators.name('Anita'), isNull);
    });

    test('letters with space and apostrophe -> valid', () {
      expect(Validators.name("O'Brien Jr"), isNull);
    });
  });

  group('Validators.password', () {
    test('null -> required', () {
      expect(Validators.password(null), 'Password is required');
    });

    test('7 chars -> too short', () {
      expect(Validators.password('short12'), 'At least 8 characters');
    });

    test('8 chars -> valid', () {
      expect(Validators.password('goodpass'), isNull);
    });
  });

  group('Validators.units', () {
    test('empty -> required', () {
      expect(Validators.units(''), 'Units are required');
    });

    test('non-numeric -> positive number', () {
      expect(Validators.units('many'), 'Enter a positive number');
    });

    test('zero -> positive number', () {
      expect(Validators.units('0'), 'Enter a positive number');
    });

    test('1 -> valid', () {
      expect(Validators.units('1'), isNull);
    });

    test('20 -> valid (upper boundary)', () {
      expect(Validators.units('20'), isNull);
    });

    test('21 -> unreasonable', () {
      expect(Validators.units('21'), 'Unreasonably high');
    });
  });

  group('Validators.required', () {
    test('empty -> uses label', () {
      expect(Validators.required('', label: 'Location'), 'Location is required');
    });

    test('non-empty -> null', () {
      expect(Validators.required('Bengaluru'), isNull);
    });
  });
}
