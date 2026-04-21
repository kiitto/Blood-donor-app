import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:blood_donor_receiver/core/utils/id_generator.dart';

import '../helpers/test_app.dart';

void main() {
  final harness = HiveTestHarness();

  setUp(() async {
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  final today = DateFormat('yyyyMMdd').format(DateTime.now());

  group('IdGenerator', () {
    test('donor() produces DNR-YYYYMMDD-### format with sequence 001', () async {
      final id = await IdGenerator.donor();
      expect(id, matches(RegExp(r'^DNR-\d{8}-\d{3}$')));
      expect(id, 'DNR-$today-001');
    });

    test('receiver() uses RCV prefix', () async {
      final id = await IdGenerator.receiver();
      expect(id.startsWith('RCV-'), isTrue);
      expect(id, 'RCV-$today-001');
    });

    test('request() uses REQ prefix', () async {
      final id = await IdGenerator.request();
      expect(id.startsWith('REQ-'), isTrue);
    });

    test('sequential donor ids increment by one', () async {
      final a = await IdGenerator.donor();
      final b = await IdGenerator.donor();
      final c = await IdGenerator.donor();
      expect(a, 'DNR-$today-001');
      expect(b, 'DNR-$today-002');
      expect(c, 'DNR-$today-003');
    });

    test('donor, receiver, request counters are independent', () async {
      await IdGenerator.donor(); // 001
      await IdGenerator.donor(); // 002
      final r = await IdGenerator.receiver();
      final q = await IdGenerator.request();
      // Separate counters: receiver + request both start at 001 in parallel.
      expect(r.endsWith('-001'), isTrue);
      expect(q.endsWith('-001'), isTrue);
    });

    test('concurrent mints do not produce duplicates', () async {
      final futures = List.generate(10, (_) => IdGenerator.donor());
      final ids = await Future.wait(futures);
      expect(ids.toSet().length, 10, reason: 'all 10 ids must be unique');
    });
  });
}
