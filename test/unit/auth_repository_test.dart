import 'package:flutter_test/flutter_test.dart';

import 'package:blood_donor_receiver/data/repositories/auth_repository.dart';

import '../helpers/test_app.dart';

void main() {
  final harness = HiveTestHarness();
  late AuthRepository repo;

  setUp(() async {
    await harness.setUp();
    repo = AuthRepository();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  group('AuthRepository.signUp', () {
    test('first sign-up succeeds and stores lowercased email', () async {
      final res = await repo.signUp(
        name: 'Anita',
        email: 'Anita@Example.Com',
        password: 'Sec1ure!',
      );
      expect(res.outcome, AuthOutcome.success);
      expect(res.user, isNotNull);
      expect(res.user!.email, 'anita@example.com');
      expect(res.user!.name, 'Anita');
      // Password should NOT be stored in plaintext.
      expect(res.user!.passwordHash, isNotEmpty);
      expect(res.user!.passwordHash, isNot('Sec1ure!'));
      expect(res.user!.passwordSalt, isNotEmpty);
    });

    test('second sign-up with same email -> emailTaken', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      final res2 = await repo.signUp(
        name: 'Anita 2',
        email: 'a@b.com',
        password: 'Diff1ure!',
      );
      expect(res2.outcome, AuthOutcome.emailTaken);
      expect(res2.user, isNull);
    });

    test('email comparison is case-insensitive', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      final res = await repo.signUp(
        name: 'Dupe',
        email: 'A@B.COM',
        password: 'Sec1ure!',
      );
      expect(res.outcome, AuthOutcome.emailTaken);
    });
  });

  group('AuthRepository.logIn', () {
    test('correct credentials -> success and sets session', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      final res = await repo.logIn(email: 'a@b.com', password: 'Sec1ure!');
      expect(res.outcome, AuthOutcome.success);
      expect(repo.currentUser()?.email, 'a@b.com');
    });

    test('unknown email -> unknownEmail', () async {
      final res = await repo.logIn(
        email: 'nobody@x.com',
        password: 'whatever1',
      );
      expect(res.outcome, AuthOutcome.unknownEmail);
    });

    test('wrong password -> invalidCredentials', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      final res = await repo.logIn(email: 'a@b.com', password: 'WrongOne!');
      expect(res.outcome, AuthOutcome.invalidCredentials);
    });
  });

  group('AuthRepository.updateProfile', () {
    test('updates provided fields only', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      final updated = await repo.updateProfile(
        email: 'a@b.com',
        phone: '9876543210',
        location: 'Bengaluru, Karnataka',
        profileComplete: true,
      );
      expect(updated.phone, '9876543210');
      expect(updated.location, 'Bengaluru, Karnataka');
      expect(updated.profileComplete, isTrue);
      // Unchanged fields preserved.
      expect(updated.name, 'Anita');

      // Re-fetch to confirm persistence.
      final reloaded = repo.findByEmail('a@b.com');
      expect(reloaded?.phone, '9876543210');
      expect(reloaded?.profileComplete, isTrue);
    });

    test('throws when user does not exist', () async {
      expect(
        () => repo.updateProfile(email: 'ghost@x.com', name: 'Ghost'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AuthRepository.logOut', () {
    test('clears current session', () async {
      await repo.signUp(
        name: 'Anita',
        email: 'a@b.com',
        password: 'Sec1ure!',
      );
      expect(repo.currentUser(), isNotNull);
      await repo.logOut();
      expect(repo.currentUser(), isNull);
    });
  });
}
