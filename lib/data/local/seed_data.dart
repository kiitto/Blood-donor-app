import '../../core/utils/id_generator.dart';
import '../models/donor_model.dart';
import '../repositories/donor_repository.dart';
import 'hive_boxes.dart';

/// Pre-loads six donor tokens across blood groups and cities so the
/// "Find Donor" screen is populated on first launch.
/// Seed runs exactly once — a meta flag guards re-insertion on subsequent launches.
class SeedData {
  SeedData._();

  static const _flag = 'seed_v1_done';

  static Future<void> ensureSeeded() async {
    final meta = HiveBoxes.metaBox();
    if (meta.get(_flag) == true) return;

    final repo = DonorRepository();
    final now = DateTime.now();

    final seeds = <_Seed>[
      _Seed('Anitha K', 'O+', 'Bengaluru, Karnataka', '9876543201', '2026-01-10'),
      _Seed('Ramesh Pillai', 'A+', 'Chennai, Tamil Nadu', '9876543202', '2025-11-22'),
      _Seed('Divya Sharma', 'B+', 'Mumbai, Maharashtra', '9876543203', '2026-02-04'),
      _Seed('Ibrahim Khan', 'AB+', 'Hyderabad, Telangana', '9876543204', '2025-09-18'),
      _Seed('Priya Menon', 'O-', 'Kochi, Kerala', '9876543205', '2026-03-01'),
      _Seed('Arjun Reddy', 'B-', 'Pune, Maharashtra', '9876543206', '2025-12-12'),
    ];

    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final id = IdGenerator.donor();
      final token = DonorToken(
        id: id,
        ownerEmail: 'seed@community.local',
        name: s.name,
        bloodGroup: s.bloodGroup,
        location: s.location,
        phone: s.phone,
        lastDonationDate: s.lastDonation,
        createdAt: now.subtract(Duration(hours: i * 6)),
      );
      await repo.insertRaw(token);
    }

    await meta.put(_flag, true);
  }
}

class _Seed {
  final String name;
  final String bloodGroup;
  final String location;
  final String phone;
  final String lastDonation;
  const _Seed(
    this.name,
    this.bloodGroup,
    this.location,
    this.phone,
    this.lastDonation,
  );
}
