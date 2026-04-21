import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/blood_compatibility.dart';
import '../../data/models/donor_model.dart';
import '../../data/models/receiver_model.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/card_shell.dart';
import '../../shared/widgets/detail_row.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/token_id_chip.dart';
import '../../state/auth_provider.dart';
import '../../state/donor_provider.dart';
import '../../state/receiver_provider.dart';
import '../../state/request_provider.dart';
import 'receiver_status_screen.dart';

enum _SortBy { recency, location, bloodGroup }

class SearchDonorsScreen extends StatefulWidget {
  final String receiverTokenId;
  const SearchDonorsScreen({super.key, required this.receiverTokenId});

  @override
  State<SearchDonorsScreen> createState() => _SearchDonorsScreenState();
}

class _SearchDonorsScreenState extends State<SearchDonorsScreen> {
  bool _compatibleOnly = true;
  _SortBy _sort = _SortBy.recency;

  @override
  Widget build(BuildContext context) {
    final receiver = context.watch<ReceiverProvider>().byId(widget.receiverTokenId);
    if (receiver == null) {
      return const _MissingReceiverScaffold();
    }

    final donors = context.watch<DonorProvider>().available;
    final reqProv = context.watch<RequestProvider>();

    final filtered = donors.where((d) {
      if (!_compatibleOnly) return true;
      return BloodCompatibility.isCompatible(
        receiverGroup: receiver.bloodGroup,
        donorGroup: d.bloodGroup,
      );
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _SortBy.recency:
          return b.createdAt.compareTo(a.createdAt);
        case _SortBy.location:
          final inCity = receiver.location.split(',').first.trim();
          final aMatch = a.location.toLowerCase().contains(inCity.toLowerCase());
          final bMatch = b.location.toLowerCase().contains(inCity.toLowerCase());
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return b.createdAt.compareTo(a.createdAt);
        case _SortBy.bloodGroup:
          return a.bloodGroup.compareTo(b.bloodGroup);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppHeader(
            eyebrow: 'Receiver',
            title: 'Find Donors',
          ),
          _ReceiverRibbon(receiver: receiver),
          _FiltersBar(
            compatibleOnly: _compatibleOnly,
            sort: _sort,
            onCompatibleChanged: (v) =>
                setState(() => _compatibleOnly = v),
            onSortChanged: (s) => setState(() => _sort = s),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    headline: 'No donors nearby',
                    body: _compatibleOnly
                        ? 'Try toggling "compatible only" off to see all donors.'
                        : 'Check back in a few minutes — new donors keep joining.',
                    action: _compatibleOnly
                        ? AppButton(
                            label: 'Show all donors',
                            kind: AppButtonKind.outline,
                            expand: false,
                            onPressed: () =>
                                setState(() => _compatibleOnly = false),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      final existing = reqProv.activeBetween(
                        donorTokenId: d.id,
                        receiverTokenId: receiver.id,
                      );
                      return _DonorCard(
                        donor: d,
                        receiver: receiver,
                        existingRequestId: existing?.id,
                        onSend: () async {
                          final user = context.read<AuthProvider>().current;
                          if (user == null) return;
                          // Re-check inside onSend in case user double-taps:
                          // activeBetween is read in build, so a stale card
                          // could try to send twice on the same pair.
                          final already = context.read<RequestProvider>().activeBetween(
                                donorTokenId: d.id,
                                receiverTokenId: receiver.id,
                              );
                          if (already != null) return;
                          final req = await context.read<RequestProvider>().send(
                                donorTokenId: d.id,
                                receiverTokenId: receiver.id,
                                senderEmail: user.email,
                                recipientEmail: d.ownerEmail,
                              );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReceiverStatusScreen(requestId: req.id),
                            ),
                          );
                        },
                        onWithdraw: () async {
                          if (existing != null) {
                            await context
                                .read<RequestProvider>()
                                .withdraw(existing.id);
                          }
                        },
                        onTrack: () {
                          if (existing != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiverStatusScreen(
                                    requestId: existing.id),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReceiverRibbon extends StatelessWidget {
  final ReceiverToken receiver;
  const _ReceiverRibbon({required this.receiver});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      color: AppColors.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TokenIdChip(id: receiver.id),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppText.body(color: AppColors.ink, size: 13.5),
                children: [
                  const TextSpan(text: 'Looking for '),
                  TextSpan(
                    text: '${receiver.unitsNeeded} unit'
                        '${receiver.unitsNeeded > 1 ? 's' : ''} of '
                        '${receiver.bloodGroup}',
                    style: AppText.bodyStrong(color: AppColors.maroon, size: 13.5),
                  ),
                  TextSpan(text: ' · ${receiver.location}'),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final bool compatibleOnly;
  final _SortBy sort;
  final ValueChanged<bool> onCompatibleChanged;
  final ValueChanged<_SortBy> onSortChanged;
  const _FiltersBar({
    required this.compatibleOnly,
    required this.sort,
    required this.onCompatibleChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _FilterToggle(
            label: 'Compatible only',
            active: compatibleOnly,
            onTap: () => onCompatibleChanged(!compatibleOnly),
          ),
          const SizedBox(width: 10),
          const Spacer(),
          _SortMenu(sort: sort, onChanged: onSortChanged),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.maroon : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        side: BorderSide(
          color: active ? AppColors.maroon : AppColors.hairlineStrong,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.check_rounded : Icons.add_rounded,
                size: 14,
                color: active ? AppColors.onMaroon : AppColors.ink,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.caption(
                        color: active ? AppColors.onMaroon : AppColors.ink,
                        size: 12.5)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final _SortBy sort;
  final ValueChanged<_SortBy> onChanged;
  const _SortMenu({required this.sort, required this.onChanged});

  String _label(_SortBy s) {
    switch (s) {
      case _SortBy.recency:     return 'Newest';
      case _SortBy.location:    return 'Nearby';
      case _SortBy.bloodGroup:  return 'Blood group';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortBy>(
      onSelected: onChanged,
      initialValue: sort,
      offset: const Offset(0, 32),
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.hairline),
      ),
      itemBuilder: (_) => _SortBy.values
          .map((s) => PopupMenuItem(
                value: s,
                height: 36,
                child: Text(_label(s), style: AppText.body(size: 13)),
              ))
          .toList(),
      child: Row(
        children: [
          Text('SORT',
              style: AppText.label(color: AppColors.inkMuted, size: 10.5)),
          const SizedBox(width: 6),
          Text(_label(sort), style: AppText.bodyStrong(size: 13)),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final DonorToken donor;
  final ReceiverToken receiver;
  final String? existingRequestId;
  final VoidCallback onSend;
  final VoidCallback onWithdraw;
  final VoidCallback onTrack;

  const _DonorCard({
    required this.donor,
    required this.receiver,
    required this.existingRequestId,
    required this.onSend,
    required this.onWithdraw,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final hasRequest = existingRequestId != null;
    final inCity = receiver.location.split(',').first.trim();
    final nearby = inCity.isNotEmpty &&
        donor.location.toLowerCase().contains(inCity.toLowerCase());

    return CardShell(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TokenIdChip(id: donor.id),
              const Spacer(),
              if (nearby)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'NEARBY',
                    style: AppText.label(color: AppColors.success, size: 10)
                        .copyWith(letterSpacing: 1.5),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.maroon,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                child: Text(
                  donor.bloodGroup,
                  style: AppText.bodyStrong(color: AppColors.onMaroon, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(donor.name, style: AppText.title(size: 18)),
          const SizedBox(height: 2),
          Text(
            donor.location,
            style: AppText.body(color: AppColors.inkMuted, size: 13),
          ),
          const Hairline(margin: EdgeInsets.symmetric(vertical: 12)),
          DetailRow(label: 'Contact', value: '+91 ${donor.phone}'),
          if (donor.lastDonationDate.isNotEmpty)
            DetailRow(label: 'Last donated', value: donor.lastDonationDate),
          const SizedBox(height: 12),
          if (hasRequest)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Withdraw',
                    kind: AppButtonKind.ghost,
                    onPressed: onWithdraw,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Track status',
                    onPressed: onTrack,
                  ),
                ),
              ],
            )
          else
            AppButton(label: 'Send request', onPressed: onSend),
        ],
      ),
    );
  }
}

class _MissingReceiverScaffold extends StatelessWidget {
  const _MissingReceiverScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const AppHeader(title: 'Find Donors'),
            Expanded(
              child: Center(
                child: Text(
                  'Receiver token no longer available.',
                  style: AppText.body(color: AppColors.inkMuted),
                ),
              ),
            ),
          ],
        ),
      );
}
