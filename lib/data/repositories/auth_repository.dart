import '../../core/utils/password_hash.dart';
import '../local/hive_boxes.dart';
import '../models/user_model.dart';

enum AuthOutcome { success, emailTaken, invalidCredentials, unknownEmail }

class AuthResult {
  final AuthOutcome outcome;
  final AppUser? user;
  const AuthResult(this.outcome, [this.user]);
}

class AuthRepository {
  static const _sessionKey = 'currentUserEmail';

  AppUser? findByEmail(String email) {
    final box = HiveBoxes.usersBox();
    final v = box.get(email.toLowerCase());
    if (v == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(v as Map));
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.toLowerCase();
    final box = HiveBoxes.usersBox();
    if (box.containsKey(key)) {
      return const AuthResult(AuthOutcome.emailTaken);
    }
    final salt = PasswordHash.newSalt();
    final user = AppUser(
      email: key,
      name: name.trim(),
      passwordHash: PasswordHash.hash(password, salt),
      passwordSalt: salt,
      createdAt: DateTime.now(),
    );
    await box.put(key, user.toMap());
    await _setSession(key);
    return AuthResult(AuthOutcome.success, user);
  }

  Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final user = findByEmail(email);
    if (user == null) return const AuthResult(AuthOutcome.unknownEmail);
    final ok = PasswordHash.verify(
      password: password,
      salt: user.passwordSalt,
      expectedHash: user.passwordHash,
    );
    if (!ok) return const AuthResult(AuthOutcome.invalidCredentials);
    await _setSession(user.email);
    return AuthResult(AuthOutcome.success, user);
  }

  Future<void> logOut() async {
    await HiveBoxes.sessionBox().delete(_sessionKey);
  }

  AppUser? currentUser() {
    final email = HiveBoxes.sessionBox().get(_sessionKey) as String?;
    if (email == null) return null;
    return findByEmail(email);
  }

  Future<AppUser> updateProfile({
    required String email,
    String? name,
    String? phone,
    String? dob,
    String? location,
    bool? profileComplete,
  }) async {
    final box = HiveBoxes.usersBox();
    final existing = findByEmail(email);
    if (existing == null) {
      throw StateError('User not found: $email');
    }
    final updated = existing.copyWith(
      name: name,
      phone: phone,
      dob: dob,
      location: location,
      profileComplete: profileComplete,
    );
    await box.put(email.toLowerCase(), updated.toMap());
    return updated;
  }

  Future<void> _setSession(String email) async {
    await HiveBoxes.sessionBox().put(_sessionKey, email);
  }
}
