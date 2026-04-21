import '../../core/utils/id_generator.dart';
import '../local/hive_boxes.dart';
import '../models/request_model.dart';
import 'donor_repository.dart';

class RequestRepository {
  final DonorRepository _donorRepo;
  RequestRepository(this._donorRepo);

  List<BloodRequest> all() {
    final box = HiveBoxes.requestsBox();
    final out = box.values
        .map((v) => BloodRequest.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  BloodRequest? byId(String id) {
    final v = HiveBoxes.requestsBox().get(id);
    if (v == null) return null;
    return BloodRequest.fromMap(Map<String, dynamic>.from(v as Map));
  }

  /// Requests sent by the given user (as a receiver).
  List<BloodRequest> bySender(String email) =>
      all().where((r) => r.senderEmail == email.toLowerCase()).toList();

  /// Requests received by the given user (as a donor).
  List<BloodRequest> byRecipient(String email) =>
      all().where((r) => r.recipientEmail == email.toLowerCase()).toList();

  /// Requests attached to a specific donor token.
  List<BloodRequest> forDonorToken(String donorTokenId) =>
      all().where((r) => r.donorTokenId == donorTokenId).toList();

  /// Existing active (non-terminal) request between this receiver token
  /// and this donor token, if any.
  BloodRequest? activeBetween({
    required String donorTokenId,
    required String receiverTokenId,
  }) {
    for (final r in all()) {
      if (r.donorTokenId == donorTokenId &&
          r.receiverTokenId == receiverTokenId &&
          r.status.isActive) {
        return r;
      }
    }
    return null;
  }

  Future<BloodRequest> create({
    required String donorTokenId,
    required String receiverTokenId,
    required String senderEmail,
    required String recipientEmail,
  }) async {
    final id = await IdGenerator.request();
    final req = BloodRequest(
      id: id,
      donorTokenId: donorTokenId,
      receiverTokenId: receiverTokenId,
      senderEmail: senderEmail.toLowerCase(),
      recipientEmail: recipientEmail.toLowerCase(),
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveBoxes.requestsBox().put(req.id, req.toMap());
    return req;
  }

  Future<BloodRequest> updateStatus(String id, RequestStatus status) async {
    final existing = byId(id);
    if (existing == null) throw StateError('Request not found: $id');

    // Acceptance closes the donor token so it drops off the search list.
    // Close the donor first: if the request write then fails, the worst case
    // is a closed token with no accepted request (recoverable); the inverse
    // (accepted request + open donor in search list) is harder to repair.
    if (status == RequestStatus.accepted) {
      await _donorRepo.closeOnAcceptance(existing.donorTokenId, existing.id);
    }

    final updated = existing.copyWith(status: status, updatedAt: DateTime.now());
    await HiveBoxes.requestsBox().put(id, updated.toMap());
    return updated;
  }

  Future<void> delete(String id) async {
    await HiveBoxes.requestsBox().delete(id);
  }
}
