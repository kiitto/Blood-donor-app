class DonorToken {
  final String id;
  final String ownerEmail;
  final String name;
  final String bloodGroup;
  final String location;
  final String phone;
  final String lastDonationDate;
  final DateTime createdAt;
  final bool closed;
  final String? acceptedRequestId;

  const DonorToken({
    required this.id,
    required this.ownerEmail,
    required this.name,
    required this.bloodGroup,
    required this.location,
    required this.phone,
    this.lastDonationDate = '',
    required this.createdAt,
    this.closed = false,
    this.acceptedRequestId,
  });

  DonorToken copyWith({
    bool? closed,
    String? acceptedRequestId,
  }) =>
      DonorToken(
        id: id,
        ownerEmail: ownerEmail,
        name: name,
        bloodGroup: bloodGroup,
        location: location,
        phone: phone,
        lastDonationDate: lastDonationDate,
        createdAt: createdAt,
        closed: closed ?? this.closed,
        acceptedRequestId: acceptedRequestId ?? this.acceptedRequestId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerEmail': ownerEmail,
        'name': name,
        'bloodGroup': bloodGroup,
        'location': location,
        'phone': phone,
        'lastDonationDate': lastDonationDate,
        'createdAt': createdAt.toIso8601String(),
        'closed': closed,
        'acceptedRequestId': acceptedRequestId,
      };

  static DonorToken fromMap(Map<String, dynamic> m) => DonorToken(
        id: m['id'] as String,
        ownerEmail: m['ownerEmail'] as String,
        name: m['name'] as String,
        bloodGroup: m['bloodGroup'] as String,
        location: m['location'] as String,
        phone: m['phone'] as String,
        lastDonationDate: (m['lastDonationDate'] ?? '') as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        closed: (m['closed'] ?? false) as bool,
        acceptedRequestId: m['acceptedRequestId'] as String?,
      );
}
