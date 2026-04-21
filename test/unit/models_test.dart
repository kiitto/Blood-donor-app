import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/data/models/donor_model.dart';
import 'package:blood_donor_receiver/data/models/receiver_model.dart';
import 'package:blood_donor_receiver/data/models/request_model.dart';
import 'package:blood_donor_receiver/data/models/user_model.dart';

void main() {
  group('AppUser', () {
    test('toMap -> fromMap round-trip preserves all fields', () {
      final u = AppUser(
        email: 'a@b.com',
        name: 'Anita',
        passwordHash: 'hash',
        passwordSalt: 'salt',
        phone: '9876543210',
        dob: '1990-01-01',
        location: 'Bengaluru, Karnataka',
        createdAt: DateTime.utc(2026, 4, 20, 10, 0, 0),
        profileComplete: true,
      );
      final again = AppUser.fromMap(u.toMap());
      expect(again.email, u.email);
      expect(again.name, u.name);
      expect(again.passwordHash, u.passwordHash);
      expect(again.passwordSalt, u.passwordSalt);
      expect(again.phone, u.phone);
      expect(again.dob, u.dob);
      expect(again.location, u.location);
      expect(again.createdAt, u.createdAt);
      expect(again.profileComplete, u.profileComplete);
    });

    test('copyWith updates only provided fields', () {
      final u = AppUser(
        email: 'a@b.com',
        name: 'Anita',
        passwordHash: 'h',
        passwordSalt: 's',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final v = u.copyWith(name: 'Anita K', profileComplete: true);
      expect(v.name, 'Anita K');
      expect(v.profileComplete, isTrue);
      expect(v.email, u.email);
      expect(v.passwordHash, u.passwordHash);
    });
  });

  group('DonorToken', () {
    test('toMap -> fromMap round-trip', () {
      final d = DonorToken(
        id: 'DNR-20260420-001',
        ownerEmail: 'a@b.com',
        name: 'Ramesh',
        bloodGroup: 'O+',
        location: 'Chennai, Tamil Nadu',
        phone: '9876543210',
        lastDonationDate: '2026-01-10',
        createdAt: DateTime.utc(2026, 4, 20),
        closed: true,
        acceptedRequestId: 'REQ-20260420-002',
      );
      final again = DonorToken.fromMap(d.toMap());
      expect(again.id, d.id);
      expect(again.ownerEmail, d.ownerEmail);
      expect(again.bloodGroup, d.bloodGroup);
      expect(again.closed, isTrue);
      expect(again.acceptedRequestId, d.acceptedRequestId);
      expect(again.createdAt, d.createdAt);
    });

    test('copyWith flips closed flag without losing other fields', () {
      final d = DonorToken(
        id: 'DNR-X',
        ownerEmail: 'o@o.com',
        name: 'Ramesh',
        bloodGroup: 'A+',
        location: 'Chennai',
        phone: '9000000000',
        createdAt: DateTime.utc(2026, 4, 20),
      );
      final d2 = d.copyWith(closed: true, acceptedRequestId: 'R1');
      expect(d2.closed, isTrue);
      expect(d2.acceptedRequestId, 'R1');
      expect(d2.name, d.name);
      expect(d2.phone, d.phone);
    });
  });

  group('ReceiverToken', () {
    test('toMap -> fromMap round-trip', () {
      final r = ReceiverToken(
        id: 'RCV-20260420-001',
        ownerEmail: 'r@x.com',
        name: 'Divya',
        bloodGroup: 'B+',
        location: 'Mumbai',
        phone: '9000000000',
        cause: 'Surgery',
        causeOther: '',
        unitsNeeded: 2,
        createdAt: DateTime.utc(2026, 4, 20),
        closed: false,
      );
      final again = ReceiverToken.fromMap(r.toMap());
      expect(again.id, r.id);
      expect(again.cause, r.cause);
      expect(again.unitsNeeded, 2);
      expect(again.closed, isFalse);
    });

    test('displayCause falls back to cause when Other is empty', () {
      final r = ReceiverToken(
        id: 'RCV-X',
        ownerEmail: 'r@x.com',
        name: 'Divya',
        bloodGroup: 'B+',
        location: 'Mumbai',
        phone: '9000000000',
        cause: 'Other',
        causeOther: '',
        unitsNeeded: 1,
        createdAt: DateTime.utc(2026, 4, 20),
      );
      expect(r.displayCause, 'Other');
    });

    test('displayCause uses causeOther when cause==Other and it is filled', () {
      final r = ReceiverToken(
        id: 'RCV-X',
        ownerEmail: 'r@x.com',
        name: 'Divya',
        bloodGroup: 'B+',
        location: 'Mumbai',
        phone: '9000000000',
        cause: 'Other',
        causeOther: 'Open-heart surgery',
        unitsNeeded: 1,
        createdAt: DateTime.utc(2026, 4, 20),
      );
      expect(r.displayCause, 'Open-heart surgery');
    });
  });

  group('BloodRequest', () {
    test('toMap -> fromMap preserves status enum', () {
      final req = BloodRequest(
        id: 'REQ-20260420-001',
        donorTokenId: 'DNR-1',
        receiverTokenId: 'RCV-1',
        senderEmail: 's@x.com',
        recipientEmail: 'r@x.com',
        status: RequestStatus.accepted,
        createdAt: DateTime.utc(2026, 4, 20),
        updatedAt: DateTime.utc(2026, 4, 20, 1),
      );
      final again = BloodRequest.fromMap(req.toMap());
      expect(again.id, req.id);
      expect(again.status, RequestStatus.accepted);
      expect(again.createdAt, req.createdAt);
      expect(again.updatedAt, req.updatedAt);
    });

    test('status isActive / isTerminal / flowIndex', () {
      expect(RequestStatus.pending.isActive, isTrue);
      expect(RequestStatus.pending.flowIndex, -1);
      expect(RequestStatus.accepted.flowIndex, 0);
      expect(RequestStatus.contacted.flowIndex, 1);
      expect(RequestStatus.arranged.flowIndex, 2);
      expect(RequestStatus.completed.flowIndex, 3);
      expect(RequestStatus.completed.isTerminal, isTrue);
      expect(RequestStatus.withdrawn.isTerminal, isTrue);
      expect(RequestStatus.declined.isTerminal, isTrue);
    });
  });
}
