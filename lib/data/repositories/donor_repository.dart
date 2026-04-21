import '../../core/utils/id_generator.dart';
import '../local/hive_boxes.dart';
import '../models/donor_model.dart';

class DonorRepository {
  List<DonorToken> all() {
    final box = HiveBoxes.donorsBox();
    final out = box.values
        .map((v) => DonorToken.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  /// Only donors that aren't closed (i.e. haven't accepted a request).
  List<DonorToken> available() => all().where((d) => !d.closed).toList();

  List<DonorToken> byOwner(String email) =>
      all().where((d) => d.ownerEmail == email.toLowerCase()).toList();

  DonorToken? byId(String id) {
    final v = HiveBoxes.donorsBox().get(id);
    if (v == null) return null;
    return DonorToken.fromMap(Map<String, dynamic>.from(v as Map));
  }

  Future<DonorToken> create({
    required String ownerEmail,
    required String name,
    required String bloodGroup,
    required String location,
    required String phone,
    String lastDonationDate = '',
  }) async {
    final id = await IdGenerator.donor();
    final token = DonorToken(
      id: id,
      ownerEmail: ownerEmail.toLowerCase(),
      name: name,
      bloodGroup: bloodGroup,
      location: location,
      phone: phone,
      lastDonationDate: lastDonationDate,
      createdAt: DateTime.now(),
    );
    await HiveBoxes.donorsBox().put(token.id, token.toMap());
    return token;
  }

  /// Used when a request is accepted: pin the request + remove from search list.
  Future<void> closeOnAcceptance(String id, String requestId) async {
    final existing = byId(id);
    if (existing == null) return;
    final updated = existing.copyWith(closed: true, acceptedRequestId: requestId);
    await HiveBoxes.donorsBox().put(id, updated.toMap());
  }

  /// For seed data only.
  Future<void> insertRaw(DonorToken token) async {
    await HiveBoxes.donorsBox().put(token.id, token.toMap());
  }
}
