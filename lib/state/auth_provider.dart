import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AppUser? _current;
  AppUser? get current => _current;
  bool get isSignedIn => _current != null;
  bool get needsProfileSetup => _current != null && !_current!.profileComplete;

  void init() {
    _current = _repo.currentUser();
    notifyListeners();
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _repo.signUp(name: name, email: email, password: password);
    if (res.outcome == AuthOutcome.success) {
      _current = res.user;
      notifyListeners();
    }
    return res;
  }

  Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final res = await _repo.logIn(email: email, password: password);
    if (res.outcome == AuthOutcome.success) {
      _current = res.user;
      notifyListeners();
    }
    return res;
  }

  Future<void> logOut() async {
    await _repo.logOut();
    _current = null;
    notifyListeners();
  }

  Future<void> completeProfile({
    required String name,
    required String phone,
    required String dob,
    required String location,
  }) async {
    if (_current == null) return;
    final updated = await _repo.updateProfile(
      email: _current!.email,
      name: name,
      phone: phone,
      dob: dob,
      location: location,
      profileComplete: true,
    );
    _current = updated;
    notifyListeners();
  }

  Future<void> editProfile({
    String? name,
    String? phone,
    String? dob,
    String? location,
  }) async {
    if (_current == null) return;
    final updated = await _repo.updateProfile(
      email: _current!.email,
      name: name,
      phone: phone,
      dob: dob,
      location: location,
    );
    _current = updated;
    notifyListeners();
  }
}
