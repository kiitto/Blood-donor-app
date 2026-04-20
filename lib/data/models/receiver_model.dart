class ReceiverToken {
  final String id;
  final String ownerEmail;
  final String name;
  final String bloodGroup;
  final String location;
  final String phone;
  final String cause;
  final String causeOther;
  final int unitsNeeded;
  final DateTime createdAt;
  final bool closed;

  const ReceiverToken({
    required this.id,
    required this.ownerEmail,
    required this.name,
    required this.bloodGroup,
    required this.location,
    required this.phone,
    required this.cause,
    this.causeOther = '',
    required this.unitsNeeded,
    required this.createdAt,
    this.closed = false,
  });

  ReceiverToken copyWith({bool? closed}) => ReceiverToken(
        id: id,
        ownerEmail: ownerEmail,
        name: name,
        bloodGroup: bloodGroup,
        location: location,
        phone: phone,
        cause: cause,
        causeOther: causeOther,
        unitsNeeded: unitsNeeded,
        createdAt: createdAt,
        closed: closed ?? this.closed,
      );

  String get displayCause =>
      cause == 'Other' && causeOther.isNotEmpty ? causeOther : cause;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerEmail': ownerEmail,
        'name': name,
        'bloodGroup': bloodGroup,
        'location': location,
        'phone': phone,
        'cause': cause,
        'causeOther': causeOther,
        'unitsNeeded': unitsNeeded,
        'createdAt': createdAt.toIso8601String(),
        'closed': closed,
      };

  static ReceiverToken fromMap(Map<String, dynamic> m) => ReceiverToken(
        id: m['id'] as String,
        ownerEmail: m['ownerEmail'] as String,
        name: m['name'] as String,
        bloodGroup: m['bloodGroup'] as String,
        location: m['location'] as String,
        phone: m['phone'] as String,
        cause: m['cause'] as String,
        causeOther: (m['causeOther'] ?? '') as String,
        unitsNeeded: (m['unitsNeeded'] as num).toInt(),
        createdAt: DateTime.parse(m['createdAt'] as String),
        closed: (m['closed'] ?? false) as bool,
      );
}
