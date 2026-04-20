enum RequestStatus {
  pending,     // sent — awaiting donor response
  accepted,    // donor accepted the request
  contacted,   // donor has contacted the patient
  arranged,    // blood arranged
  completed,   // donated / received
  declined,    // donor declined
  withdrawn,   // receiver withdrew before acceptance
}

extension RequestStatusMeta on RequestStatus {
  String get wire => name;

  static RequestStatus parse(String s) =>
      RequestStatus.values.firstWhere((e) => e.name == s,
          orElse: () => RequestStatus.pending);

  bool get isTerminal =>
      this == RequestStatus.completed ||
      this == RequestStatus.declined ||
      this == RequestStatus.withdrawn;

  bool get isActive => !isTerminal;

  /// Index into the 4-step flow (accepted → contacted → arranged → completed).
  /// Returns -1 if not yet started. Used by the status tracker UI.
  int get flowIndex {
    switch (this) {
      case RequestStatus.pending:   return -1;
      case RequestStatus.accepted:  return 0;
      case RequestStatus.contacted: return 1;
      case RequestStatus.arranged:  return 2;
      case RequestStatus.completed: return 3;
      default: return -1;
    }
  }
}

class BloodRequest {
  final String id;
  final String donorTokenId;
  final String receiverTokenId;
  final String senderEmail;      // the receiver-token owner who sent it
  final String recipientEmail;   // the donor-token owner who receives it
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BloodRequest({
    required this.id,
    required this.donorTokenId,
    required this.receiverTokenId,
    required this.senderEmail,
    required this.recipientEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  BloodRequest copyWith({
    RequestStatus? status,
    DateTime? updatedAt,
  }) =>
      BloodRequest(
        id: id,
        donorTokenId: donorTokenId,
        receiverTokenId: receiverTokenId,
        senderEmail: senderEmail,
        recipientEmail: recipientEmail,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'donorTokenId': donorTokenId,
        'receiverTokenId': receiverTokenId,
        'senderEmail': senderEmail,
        'recipientEmail': recipientEmail,
        'status': status.wire,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static BloodRequest fromMap(Map<String, dynamic> m) => BloodRequest(
        id: m['id'] as String,
        donorTokenId: m['donorTokenId'] as String,
        receiverTokenId: m['receiverTokenId'] as String,
        senderEmail: m['senderEmail'] as String,
        recipientEmail: m['recipientEmail'] as String,
        status: RequestStatusMeta.parse(m['status'] as String),
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
