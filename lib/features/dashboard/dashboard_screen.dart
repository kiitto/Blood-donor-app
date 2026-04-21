import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/request_model.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/blood_drop.dart';
import '../../shared/widgets/card_shell.dart';
import '../../state/auth_provider.dart';
import '../../state/donor_provider.dart';
import '../../state/request_provider.dart';
import '../donor/donor_registration_screen.dart';
import '../profile/profile_screen.dart';
import '../receiver/receiver_registration_screen.dart';
import 'location_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().current;
    if (user == null) return const SizedBox.shrink();

    final donorsMine = context.watch<DonorProvider>().byOwner(user.email);
    final sentRequests = context.watch<RequestProvider>().bySender(user.email);

    final activeDonorTokens = donorsMine.where((d) => !d.closed).length;
    final activeSentRequests =
        sentRequests.where((r) => r.status.isActive).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(name: user.name),
                      const SizedBox(height: 22),
                      _LocationBar(
                        location: user.location,
                        onTap: () async {
                          await showLocationSheet(
                            context,
                            initial: user.location,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'How can you help today?',
                        style: AppText.headline(size: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick a role for this session — you can switch anytime.',
                        style: AppText.body(color: AppColors.inkMuted, size: 14),
                      ),
                      const SizedBox(height: 22),
                      _RoleCard(
                        title: 'Donate blood',
                        body: 'Register yourself (or a friend) as a donor. '
                            'We\'ll show your token to receivers nearby.',
                        icon: Icons.volunteer_activism_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DonorRegistrationScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RoleCard(
                        title: 'Receive blood',
                        body: 'Register the patient and we\'ll show compatible '
                            'donors nearby with a way to reach them.',
                        icon: Icons.bloodtype_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReceiverRegistrationScreen(),
                          ),
                        ),
                      ),
                      if (activeDonorTokens > 0 || activeSentRequests > 0) ...[
                        const SizedBox(height: 34),
                        Text('Your activity',
                            style: AppText.title(size: 15)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                number: activeDonorTokens,
                                label: 'Active donor tokens',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                number: activeSentRequests,
                                label: 'Open requests sent',
                              ),
                            ),
                          ],
                        ),
                      ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppBottomNav(
                onTap: (a) {
                  switch (a) {
                    case BottomNavAction.donate:
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const DonorRegistrationScreen(),
                      ));
                      break;
                    case BottomNavAction.receive:
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReceiverRegistrationScreen(),
                      ));
                      break;
                    case BottomNavAction.profile:
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ));
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  const _TopBar({required this.name});

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Hello, $firstName.',
            style: AppText.headline(size: 26),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const BloodDrop(size: 22, color: AppColors.red),
      ],
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String location;
  final VoidCallback onTap;
  const _LocationBar({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 18, color: AppColors.maroon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're in",
                    style: AppText.caption(
                        color: AppColors.inkMuted, size: 11.5)),
                const SizedBox(height: 2),
                Text(
                  location.isEmpty ? 'Set your location' : location,
                  style: AppText.bodyStrong(size: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text('Change',
              style: AppText.bodyStrong(color: AppColors.maroon, size: 13)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                child: Icon(icon, color: AppColors.maroon, size: 22),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.headline(size: 22).copyWith(height: 1.1),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppText.body(color: AppColors.inkMuted, size: 13.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, left: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int number;
  final String label;
  const _StatTile({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number',
            style: AppText.display(size: 38, color: AppColors.maroon)
                .copyWith(height: 1.0),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.caption(color: AppColors.ink).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}
