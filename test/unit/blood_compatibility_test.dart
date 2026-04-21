import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/core/utils/blood_compatibility.dart';

void main() {
  group('BloodCompatibility.donorsFor', () {
    test('O+ receives from O+ and O-', () {
      expect(BloodCompatibility.donorsFor('O+'), unorderedEquals(['O+', 'O-']));
    });

    test('O- receives from O- only', () {
      expect(BloodCompatibility.donorsFor('O-'), ['O-']);
    });

    test('A+ receives from A+/A-/O+/O-', () {
      expect(
        BloodCompatibility.donorsFor('A+'),
        unorderedEquals(['A+', 'A-', 'O+', 'O-']),
      );
    });

    test('A- receives from A- and O-', () {
      expect(
        BloodCompatibility.donorsFor('A-'),
        unorderedEquals(['A-', 'O-']),
      );
    });

    test('B+ receives from B+/B-/O+/O-', () {
      expect(
        BloodCompatibility.donorsFor('B+'),
        unorderedEquals(['B+', 'B-', 'O+', 'O-']),
      );
    });

    test('B- receives from B- and O-', () {
      expect(
        BloodCompatibility.donorsFor('B-'),
        unorderedEquals(['B-', 'O-']),
      );
    });

    test('AB+ is universal recipient (all 8 groups)', () {
      expect(BloodCompatibility.donorsFor('AB+').length, 8);
      expect(
        BloodCompatibility.donorsFor('AB+'),
        unorderedEquals(['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']),
      );
    });

    test('AB- receives from all 4 negative groups', () {
      expect(
        BloodCompatibility.donorsFor('AB-'),
        unorderedEquals(['O-', 'A-', 'B-', 'AB-']),
      );
    });

    test('unknown receiver group returns empty list', () {
      expect(BloodCompatibility.donorsFor('XY+'), isEmpty);
    });
  });

  group('BloodCompatibility.isCompatible', () {
    test('O- is universal donor (compatible with all 8 groups)', () {
      for (final r in ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']) {
        expect(
          BloodCompatibility.isCompatible(
            receiverGroup: r,
            donorGroup: 'O-',
          ),
          isTrue,
          reason: 'O- should be compatible with $r',
        );
      }
    });

    test('AB+ donor only compatible with AB+ receiver', () {
      for (final r in ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB-']) {
        expect(
          BloodCompatibility.isCompatible(
            receiverGroup: r,
            donorGroup: 'AB+',
          ),
          isFalse,
          reason: 'AB+ donor should NOT be compatible with $r',
        );
      }
      expect(
        BloodCompatibility.isCompatible(
          receiverGroup: 'AB+',
          donorGroup: 'AB+',
        ),
        isTrue,
      );
    });

    test('A+ donor incompatible with B+ receiver', () {
      expect(
        BloodCompatibility.isCompatible(
          receiverGroup: 'B+',
          donorGroup: 'A+',
        ),
        isFalse,
      );
    });
  });
}
