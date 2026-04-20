class AppUser {
  final String email;
  final String name;
  final String passwordHash;
  final String passwordSalt;
  final String phone;
  final String dob;
  final String location;
  final DateTime createdAt;
  final bool profileComplete;

  const AppUser({
    required this.email,
    required this.name,
    required this.passwordHash,
    required this.passwordSalt,
    this.phone = '',
    this.dob = '',
    this.location = '',
    required this.createdAt,
    this.profileComplete = false,
  });

  AppUser copyWith({
    String? name,
    String? phone,
    String? dob,
    String? location,
    bool? profileComplete,
  }) =>
      AppUser(
        email: email,
        name: name ?? this.name,
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        phone: phone ?? this.phone,
        dob: dob ?? this.dob,
        location: location ?? this.location,
        createdAt: createdAt,
        profileComplete: profileComplete ?? this.profileComplete,
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'phone': phone,
        'dob': dob,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'profileComplete': profileComplete,
      };

  static AppUser fromMap(Map<String, dynamic> m) => AppUser(
        email: m['email'] as String,
        name: m['name'] as String,
        passwordHash: m['passwordHash'] as String,
        passwordSalt: m['passwordSalt'] as String,
        phone: (m['phone'] ?? '') as String,
        dob: (m['dob'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        profileComplete: (m['profileComplete'] ?? false) as bool,
      );
}
