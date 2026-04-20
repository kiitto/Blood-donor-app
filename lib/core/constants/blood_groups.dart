class BloodGroups {
  BloodGroups._();

  static const all = <String>[
    'O+', 'O-',
    'A+', 'A-',
    'B+', 'B-',
    'AB+', 'AB-',
  ];

  static bool isValid(String? g) => g != null && all.contains(g);
}
