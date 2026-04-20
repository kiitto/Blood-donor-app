import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../data/models/receiver_model.dart';
import '../data/repositories/receiver_repository.dart';

class ReceiverProvider extends ChangeNotifier {
  final ReceiverRepository _repo = ReceiverRepository();
  StreamSubscription<BoxEvent>? _sub;

  List<ReceiverToken> _all = const [];
  List<ReceiverToken> get all => _all;

  List<ReceiverToken> byOwner(String email) =>
      _all.where((r) => r.ownerEmail == email.toLowerCase()).toList();

  ReceiverToken? byId(String id) {
    for (final r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }

  void init() {
    _all = _repo.all();
    _sub = HiveBoxes.receiversBox().watch().listen((_) {
      _all = _repo.all();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<ReceiverToken> create({
    required String ownerEmail,
    required String name,
    required String bloodGroup,
    required String location,
    required String phone,
    required String cause,
    String causeOther = '',
    required int unitsNeeded,
  }) =>
      _repo.create(
        ownerEmail: ownerEmail,
        name: name,
        bloodGroup: bloodGroup,
        location: location,
        phone: phone,
        cause: cause,
        causeOther: causeOther,
        unitsNeeded: unitsNeeded,
      );

  Future<void> close(String id) => _repo.close(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
