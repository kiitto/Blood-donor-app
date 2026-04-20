/// Donor compatibility matrix. Given a receiver blood group, which donor groups
/// can safely give? AB+ is universal recipient, O- is universal donor.
class BloodCompatibility {
  BloodCompatibility._();

  static const _matrix = <String, List<String>>{
    'O+':  ['O+', 'O-'],
    'O-':  ['O-'],
    'A+':  ['A+', 'A-', 'O+', 'O-'],
    'A-':  ['A-', 'O-'],
    'B+':  ['B+', 'B-', 'O+', 'O-'],
    'B-':  ['B-', 'O-'],
    'AB+': ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'],
    'AB-': ['O-', 'A-', 'B-', 'AB-'],
  };

  static List<String> donorsFor(String receiverGroup) =>
      _matrix[receiverGroup] ?? const [];

  static bool isCompatible({
    required String receiverGroup,
    required String donorGroup,
  }) =>
      donorsFor(receiverGroup).contains(donorGroup);
}
