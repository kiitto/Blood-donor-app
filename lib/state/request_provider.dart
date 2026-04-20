import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../data/models/request_model.dart';
import '../data/repositories/donor_repository.dart';
import '../data/repositories/request_repository.dart';

class RequestProvider extends ChangeNotifier {
  final RequestRepository _repo = RequestRepository(DonorRepository());
  StreamSubscription<BoxEvent>? _sub;

  List<BloodRequest> _all = const [];
  List<BloodRequest> get all => _all;

  List<BloodRequest> bySender(String email) =>
      _all.where((r) => r.senderEmail == email.toLowerCase()).toList();

  List<BloodRequest> byRecipient(String email) =>
      _all.where((r) => r.recipientEmail == email.toLowerCase()).toList();

  List<BloodRequest> forDonorToken(String donorTokenId) =>
      _all.where((r) => r.donorTokenId == donorTokenId).toList();

  BloodRequest? byId(String id) {
    for (final r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }

  BloodRequest? activeBetween({
    required String donorTokenId,
    required String receiverTokenId,
  }) =>
      _repo.activeBetween(
        donorTokenId: donorTokenId,
        receiverTokenId: receiverTokenId,
      );

  void init() {
    _all = _repo.all();
    _sub = HiveBoxes.requestsBox().watch().listen((_) {
      _all = _repo.all();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<BloodRequest> send({
    required String donorTokenId,
    required String receiverTokenId,
    required String senderEmail,
    required String recipientEmail,
  }) =>
      _repo.create(
        donorTokenId: donorTokenId,
        receiverTokenId: receiverTokenId,
        senderEmail: senderEmail,
        recipientEmail: recipientEmail,
      );

  Future<BloodRequest> advance(String id, RequestStatus next) =>
      _repo.updateStatus(id, next);

  Future<void> withdraw(String id) => _repo.updateStatus(id, RequestStatus.withdrawn);

  Future<void> decline(String id) => _repo.updateStatus(id, RequestStatus.declined);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
