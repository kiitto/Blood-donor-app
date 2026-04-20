import '../../core/utils/id_generator.dart';
import '../local/hive_boxes.dart';
import '../models/receiver_model.dart';

class ReceiverRepository {
  List<ReceiverToken> all() {
    final box = HiveBoxes.receiversBox();
    final out = box.values
        .map((v) => ReceiverToken.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  List<ReceiverToken> byOwner(String email) =>
      all().where((r) => r.ownerEmail == email.toLowerCase()).toList();

  ReceiverToken? byId(String id) {
    final v = HiveBoxes.receiversBox().get(id);
    if (v == null) return null;
    return ReceiverToken.fromMap(Map<String, dynamic>.from(v as Map));
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
  }) async {
    final token = ReceiverToken(
      id: IdGenerator.receiver(),
      ownerEmail: ownerEmail.toLowerCase(),
      name: name,
      bloodGroup: bloodGroup,
      location: location,
      phone: phone,
      cause: cause,
      causeOther: causeOther,
      unitsNeeded: unitsNeeded,
      createdAt: DateTime.now(),
    );
    await HiveBoxes.receiversBox().put(token.id, token.toMap());
    return token;
  }

  Future<void> close(String id) async {
    final existing = byId(id);
    if (existing == null) return;
    await HiveBoxes.receiversBox().put(id, existing.copyWith(closed: true).toMap());
  }
}
