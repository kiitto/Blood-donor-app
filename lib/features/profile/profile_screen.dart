import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/donor_model.dart';
import '../../data/models/request_model.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/blood_drop.dart';
import '../../shared/widgets/card_shell.dart';
import '../../shared/widgets/detail_row.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/token_id_chip.dart';
import '../../state/auth_provider.dart';
import '../../state/donor_provider.dart';
import '../../state/receiver_provider.dart';
import '../../state/request_provider.dart';
import '../auth/login_screen.dart';
import '../donor/donor_token_requests_screen.dart';
import '../receiver/receiver_status_screen.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().current;
    if (user == null) return const SizedBox.shrink();

    final donorTokens = context.watch<DonorProvider>().byOwner(user.email);
    final sentRequests = context.watch<RequestProvider>().bySender(user.email);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            AppHeader(
              eyebrow: 'Account',
              title: 'Profile',
              trailing: InkResponse(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                      title: Text('Log out?', style: AppText.title(size: 17)),
                      content: Text(
                        'You can log back in with your email and password.',
                        style: AppText.body(color: AppColors.inkMuted, size: 13.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Stay',
                              style:
                                  AppText.button(color: AppColors.ink, size: 13)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Log out',
                              style: AppText.button(color: AppColors.danger, size: 13)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().logOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  }
                },
                radius: 22,
                child: const Icon(Icons.logout_rounded,
                    size: 20, color: AppColors.onMaroon),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                    child: _WelcomeCard(
                      name: user.name,
                      email: user.email,
                      phone: user.phone,
                      dob: user.dob,
                      location: user.location,
                      onEdit: () async {
                        await showEditProfileSheet(context);
                      },
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.hairline),
                      ),
                    ),
                    child: TabBar(
                      indicatorColor: AppColors.maroon,
                      indicatorWeight: 2,
                      labelColor: AppColors.maroon,
                      unselectedLabelColor: AppColors.inkMuted,
                      dividerColor: Colors.transparent,
                      labelStyle: AppText.bodyStrong(size: 13),
                      unselectedLabelStyle: AppText.body(size: 13),
                      tabs: [
                        Tab(text: 'Tokens (${donorTokens.length})'),
                        Tab(text: 'Requests (${sentRequests.length})'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _DonorTokensList(tokens: donorTokens),
                        _SentRequestsList(requests: sentRequests),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String dob;
  final String location;
  final VoidCallback onEdit;
  const _WelcomeCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.location,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => CardShell(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.maroon,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                  alignment: Alignment.center,
                  child: const BloodDrop(size: 22, color: AppColors.onMaroon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome',
                          style: AppText.caption(color: AppColors.inkMuted, size: 12)),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: AppText.headline(size: 24),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.maroon,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      side: BorderSide(color: AppColors.hairlineStrong),
                    ),
                    minimumSize: const Size(0, 30),
                  ),
                  child: Text('EDIT',
                      style: AppText.button(color: AppColors.maroon, size: 11)),
                ),
              ],
            ),
            const Hairline(margin: EdgeInsets.symmetric(vertical: 14)),
            DetailRow(label: 'Email', value: email),
            DetailRow(
              label: 'Phone',
              value: phone.isEmpty ? '—' : '+91 $phone',
            ),
            DetailRow(label: 'DOB', value: dob),
            DetailRow(label: 'Location', value: location),
          ],
        ),
      );
}

class _DonorTokensList extends StatelessWidget {
  final List<DonorToken> tokens;
  const _DonorTokensList({required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return const EmptyState(
        headline: 'No donor tokens yet',
        body: "When you register as a donor, your token appears here. "
            "Receivers can then send you requests.",
      );
    }
    final reqProv = context.watch<RequestProvider>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      itemCount: tokens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = tokens[i];
        final reqs = reqProv.forDonorToken(t.id);
        final pending = reqs.where((r) => r.status == RequestStatus.pending).length;
        return CardShell(
          padding: const EdgeInsets.all(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DonorTokenRequestsScreen(token: t),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TokenIdChip(id: t.id),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.maroon,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                    child: Text(
                      t.bloodGroup,
                      style: AppText.bodyStrong(
                          color: AppColors.onMaroon, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(t.name, style: AppText.title(size: 17)),
              const SizedBox(height: 2),
              Text(t.location,
                  style: AppText.body(color: AppColors.inkMuted, size: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    t.closed ? 'Closed · has accepted request' : 'Active',
                    style: AppText.caption(
                      color: t.closed ? AppColors.inkMuted : AppColors.success,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  if (pending > 0)
                    Text(
                      '$pending pending',
                      style: AppText.caption(color: AppColors.red)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.ink),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SentRequestsList extends StatelessWidget {
  final List<BloodRequest> requests;
  const _SentRequestsList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const EmptyState(
        headline: 'No requests sent',
        body: "When you send a request from the 'Find Donor' screen, "
            "you'll track it here.",
      );
    }
    final donorProv = context.watch<DonorProvider>();
    final rcvProv = context.watch<ReceiverProvider>();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = requests[i];
        final donor = donorProv.byId(r.donorTokenId);
        final receiver = rcvProv.byId(r.receiverTokenId);
        return CardShell(
          padding: const EdgeInsets.all(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiverStatusScreen(requestId: r.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TokenIdChip(id: r.id),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM').format(r.updatedAt),
                    style:
                        AppText.caption(color: AppColors.inkMuted, size: 11.5),
                  ),
                ],
              ),
              const Hairline(margin: EdgeInsets.symmetric(vertical: 12)),
              DetailRow(
                label: 'Donor',
                value: donor?.name ?? '—',
                strong: true,
              ),
              DetailRow(
                label: 'Patient',
                value: receiver?.name ?? '—',
              ),
              DetailRow(
                label: 'Group',
                value: donor?.bloodGroup ?? '—',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusPill(status: r.status),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.ink),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final RequestStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      RequestStatus.pending => 'Awaiting donor',
      RequestStatus.accepted => 'Accepted',
      RequestStatus.contacted => 'In progress',
      RequestStatus.arranged => 'Blood arranged',
      RequestStatus.completed => 'Completed',
      RequestStatus.declined => 'Declined',
      RequestStatus.withdrawn => 'Withdrawn',
    };
    final color = switch (status) {
      RequestStatus.completed => AppColors.success,
      RequestStatus.declined => AppColors.danger,
      RequestStatus.withdrawn => AppColors.inkMuted,
      _ => AppColors.maroon,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Text(
        label,
        style: AppText.caption(color: color, size: 11.5)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}
