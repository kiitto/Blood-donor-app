import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../data/models/donor_model.dart';
import '../data/repositories/donor_repository.dart';

class DonorProvider extends ChangeNotifier {
  final DonorRepository _repo = DonorRepository();
  StreamSubscription<BoxEvent>? _sub;

  List<DonorToken> _all = const [];
  List<DonorToken> get all => _all;

  List<DonorToken> get available => _all.where((d) => !d.closed).toList();

  List<DonorToken> byOwner(String email) =>
      _all.where((d) => d.ownerEmail == email.toLowerCase()).toList();

  DonorToken? byId(String id) {
    for (final d in _all) {
      if (d.id == id) return d;
    }
    return null;
  }

  void init() {
    _all = _repo.all();
    _sub = HiveBoxes.donorsBox().watch().listen((_) {
      _all = _repo.all();
      notifyListeners();
    });
    notifyListeners();
  }

  Future<DonorToken> create({
    required String ownerEmail,
    required String name,
    required String bloodGroup,
    required String location,
    required String phone,
    String lastDonationDate = '',
  }) =>
      _repo.create(
        ownerEmail: ownerEmail,
        name: name,
        bloodGroup: bloodGroup,
        location: location,
        phone: phone,
        lastDonationDate: lastDonationDate,
      );

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
