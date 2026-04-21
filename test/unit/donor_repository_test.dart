import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/data/repositories/donor_repository.dart';

import '../helpers/test_app.dart';

void main() {
  final harness = HiveTestHarness();
  late DonorRepository repo;

  setUp(() async {
    await harness.setUp();
    repo = DonorRepository();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('DonorRepository', () {
    test('create returns token with minted id and persists', () async {
      final t = await repo.create(
        ownerEmail: 'A@B.com',
        name: 'Anita',
        bloodGroup: 'O+',
        location: 'Bengaluru',
        phone: '9876543210',
      );
      expect(t.id, matches(RegExp(r'^DNR-\d{8}-\d{3}$')));
      expect(t.ownerEmail, 'a@b.com'); // lowercased
      expect(t.closed, isFalse);
      expect(repo.all().length, 1);
      expect(repo.byId(t.id)?.bloodGroup, 'O+');
    });

    test('byId returns null for missing id', () {
      expect(repo.byId('DNR-00000000-999'), isNull);
    });

    test('byOwner filters by email (case-insensitive)', () async {
      await repo.create(
        ownerEmail: 'a@b.com',
        name: 'Anita',
        bloodGroup: 'O+',
        location: 'Bengaluru',
        phone: '9876543210',
      );
      await repo.create(
        ownerEmail: 'c@d.com',
        name: 'Other',
        bloodGroup: 'A+',
        location: 'Chennai',
        phone: '9000000001',
      );
      final mine = repo.byOwner('A@B.com');
      expect(mine.length, 1);
      expect(mine.first.name, 'Anita');
    });

    test('available excludes closed donors', () async {
      final a = await repo.create(
        ownerEmail: 'a@b.com',
        name: 'Anita',
        bloodGroup: 'O+',
        location: 'Bengaluru',
        phone: '9876543210',
      );
      await repo.create(
        ownerEmail: 'c@d.com',
        name: 'Other',
        bloodGroup: 'A+',
        location: 'Chennai',
        phone: '9000000001',
      );
      expect(repo.available().length, 2);
      await repo.closeOnAcceptance(a.id, 'REQ-X-001');
      final avail = repo.available();
      expect(avail.length, 1);
      expect(avail.first.name, 'Other');
    });

    test('closeOnAcceptance sets closed=true and pins request id', () async {
      final a = await repo.create(
        ownerEmail: 'a@b.com',
        name: 'Anita',
        bloodGroup: 'O+',
        location: 'Bengaluru',
        phone: '9876543210',
      );
      await repo.closeOnAcceptance(a.id, 'REQ-X-001');
      final after = repo.byId(a.id)!;
      expect(after.closed, isTrue);
      expect(after.acceptedRequestId, 'REQ-X-001');
    });

    test('closeOnAcceptance on missing id is a no-op', () async {
      expect(
        () => repo.closeOnAcceptance('DNR-00000000-999', 'REQ-X-001'),
        returnsNormally,
      );
    });

    test('all() is sorted newest first', () async {
      final first = await repo.create(
        ownerEmail: 'a@b.com',
        name: 'First',
        bloodGroup: 'O+',
        location: 'Bengaluru',
        phone: '9000000000',
      );
      // A tiny delay to guarantee createdAt ordering.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await repo.create(
        ownerEmail: 'a@b.com',
        name: 'Second',
        bloodGroup: 'A+',
        location: 'Chennai',
        phone: '9000000001',
      );
      final list = repo.all();
      expect(list.first.id, second.id);
      expect(list.last.id, first.id);
    });
  });
}
