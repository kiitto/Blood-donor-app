import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/data/models/request_model.dart';
import 'package:blood_donor_receiver/data/repositories/donor_repository.dart';
import 'package:blood_donor_receiver/data/repositories/request_repository.dart';

import '../helpers/test_app.dart';

void main() {
  final harness = HiveTestHarness();
  late DonorRepository donors;
  late RequestRepository requests;

  setUp(() async {
    await harness.setUp();
    donors = DonorRepository();
    requests = RequestRepository(donors);
  });

  tearDown(() async {
    await harness.tearDown();
  });

  Future<String> _makeDonor() async {
    final t = await donors.create(
      ownerEmail: 'donor@x.com',
      name: 'Donor',
      bloodGroup: 'O+',
      location: 'Bengaluru',
      phone: '9876543210',
    );
    return t.id;
  }

  group('RequestRepository.create', () {
    test('returns new request with status pending', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-1',
        senderEmail: 'Sender@X.com',
        recipientEmail: 'Donor@X.com',
      );
      expect(req.status, RequestStatus.pending);
      expect(req.senderEmail, 'sender@x.com'); // lowercased
      expect(req.recipientEmail, 'donor@x.com');
      expect(req.id, matches(RegExp(r'^REQ-\d{8}-\d{3}$')));
      expect(requests.byId(req.id)?.status, RequestStatus.pending);
    });
  });

  group('RequestRepository.updateStatus', () {
    test('accepted -> closes donor token', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-1',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      expect(donors.byId(donorId)!.closed, isFalse);
      await requests.updateStatus(req.id, RequestStatus.accepted);
      final donor = donors.byId(donorId)!;
      expect(donor.closed, isTrue);
      expect(donor.acceptedRequestId, req.id);
    });

    test('non-accepted status does not close donor', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-1',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      await requests.updateStatus(req.id, RequestStatus.contacted);
      expect(donors.byId(donorId)!.closed, isFalse);
    });

    test('throws when id missing', () async {
      expect(
        () => requests.updateStatus('REQ-does-not-exist', RequestStatus.accepted),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('RequestRepository.activeBetween', () {
    test('returns the pending/accepted/... request when one exists', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      final found = requests.activeBetween(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
      );
      expect(found?.id, req.id);
    });

    test('returns null after request is completed (terminal)', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      await requests.updateStatus(req.id, RequestStatus.completed);
      final found = requests.activeBetween(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
      );
      expect(found, isNull);
    });

    test('returns null after withdrawal', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      await requests.updateStatus(req.id, RequestStatus.withdrawn);
      expect(
        requests.activeBetween(
          donorTokenId: donorId,
          receiverTokenId: 'RCV-7',
        ),
        isNull,
      );
    });

    test('returns null after decline', () async {
      final donorId = await _makeDonor();
      final req = await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-7',
        senderEmail: 's@x.com',
        recipientEmail: 'donor@x.com',
      );
      await requests.updateStatus(req.id, RequestStatus.declined);
      expect(
        requests.activeBetween(
          donorTokenId: donorId,
          receiverTokenId: 'RCV-7',
        ),
        isNull,
      );
    });

    test('returns null when no request exists', () {
      expect(
        requests.activeBetween(
          donorTokenId: 'DNR-X',
          receiverTokenId: 'RCV-X',
        ),
        isNull,
      );
    });
  });

  group('RequestRepository querying', () {
    test('bySender / byRecipient filter by email', () async {
      final donorId = await _makeDonor();
      await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-1',
        senderEmail: 'alice@x.com',
        recipientEmail: 'donor@x.com',
      );
      await requests.create(
        donorTokenId: donorId,
        receiverTokenId: 'RCV-2',
        senderEmail: 'bob@x.com',
        recipientEmail: 'donor@x.com',
      );
      expect(requests.bySender('alice@x.com').length, 1);
      expect(requests.byRecipient('donor@x.com').length, 2);
      expect(requests.forDonorToken(donorId).length, 2);
    });
  });
}
