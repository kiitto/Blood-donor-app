import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/request_model.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/card_shell.dart';
import '../../shared/widgets/detail_row.dart';
import '../../shared/widgets/status_tracker.dart';
import '../../shared/widgets/token_id_chip.dart';
import '../../state/donor_provider.dart';
import '../../state/receiver_provider.dart';
import '../../state/request_provider.dart';

class ReceiverStatusScreen extends StatelessWidget {
  final String requestId;
  const ReceiverStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final reqProv = context.watch<RequestProvider>();
    final donorProv = context.watch<DonorProvider>();
    final rcvProv = context.watch<ReceiverProvider>();

    final req = reqProv.byId(requestId);
    if (req == null) return const _MissingRequestScaffold();

    final donor = donorProv.byId(req.donorTokenId);
    final receiver = rcvProv.byId(req.receiverTokenId);

    // 4-step receiver view: Request sent → Accepted → Blood arranged → Received.
    // We don't expose the donor's "contacted" stage here because it's donor-internal.
    final steps = <StatusStep>[
      StatusStep('Request sent', _sentState(req.status)),
      StatusStep('Request accepted', _stateAt(req.status, 0)),
      StatusStep('Blood arranged', _stateAt(req.status, 2)),
      StatusStep('Received', _stateAt(req.status, 3)),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppHeader(
            eyebrow: 'Receiver',
            title: 'Receiver Status',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                CardShell(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TokenIdChip(id: req.id),
                          const Spacer(),
                          Text(
                            _badge(req.status),
                            style: AppText.caption(color: _badgeColor(req.status))
                                .copyWith(fontWeight: FontWeight.w600),
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
                        label: 'Blood group',
                        value: donor?.bloodGroup ?? '—',
                      ),
                      DetailRow(
                        label: 'Contact',
                        value: donor == null ? '—' : '+91 ${donor.phone}',
                      ),
                      DetailRow(
                        label: 'Units',
                        value: receiver == null
                            ? '—'
                            : receiver.unitsNeeded.toString(),
                      ),
                      DetailRow(
                        label: 'Patient',
                        value: receiver?.name ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('PROGRESS', style: AppText.label()),
                const SizedBox(height: 14),
                StatusTracker(steps: steps),
                const SizedBox(height: 30),
                ..._actions(context, req),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, BloodRequest req) {
    switch (req.status) {
      case RequestStatus.pending:
        return [
          AppButton(
            label: 'Withdraw request',
            kind: AppButtonKind.outline,
            onPressed: () async {
              await context.read<RequestProvider>().withdraw(req.id);
              if (context.mounted) Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'You can withdraw only before the donor accepts.',
            style: AppText.caption(color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
        ];
      case RequestStatus.accepted:
      case RequestStatus.contacted:
      case RequestStatus.arranged:
        return [
          AppButton(
            label: 'Mark as received',
            onPressed: () async {
              await context
                  .read<RequestProvider>()
                  .advance(req.id, RequestStatus.completed);
              if (context.mounted) Navigator.of(context).maybePop();
            },
          ),
        ];
      case RequestStatus.completed:
        return [
          Container(
            padding: const EdgeInsets.all(14),
            color: AppColors.surfaceMuted,
            child: Text(
              'Transfusion complete — thank you for using the app.',
              style: AppText.body(color: AppColors.success, size: 14)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ];
      case RequestStatus.declined:
        return [
          Container(
            padding: const EdgeInsets.all(14),
            color: AppColors.surfaceMuted,
            child: Text(
              'The donor declined. You can send a new request to another donor.',
              style: AppText.body(color: AppColors.inkMuted, size: 14),
            ),
          ),
        ];
      case RequestStatus.withdrawn:
        return [
          Container(
            padding: const EdgeInsets.all(14),
            color: AppColors.surfaceMuted,
            child: Text(
              'You withdrew this request.',
              style: AppText.body(color: AppColors.inkMuted, size: 14),
            ),
          ),
        ];
    }
  }

  static StatusMarkState _sentState(RequestStatus s) =>
      s == RequestStatus.pending ? StatusMarkState.current : StatusMarkState.done;

  /// Receiver's 4-step view. The donor's internal "contacted" stage is folded
  /// into the "Blood arranged" step so the tracker keeps moving for the
  /// receiver, even while the donor is still working on the arrangement.
  static StatusMarkState _stateAt(RequestStatus s, int flowIndex) {
    final idx = s.flowIndex;
    if (idx < 0) return StatusMarkState.pending;
    if (s == RequestStatus.contacted && flowIndex == 2) {
      return StatusMarkState.current;
    }
    if (idx > flowIndex) return StatusMarkState.done;
    if (idx == flowIndex) return StatusMarkState.current;
    return StatusMarkState.pending;
  }

  static String _badge(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:   return 'Awaiting donor';
      case RequestStatus.accepted:  return 'Accepted';
      case RequestStatus.contacted: return 'In progress';
      case RequestStatus.arranged:  return 'Blood arranged';
      case RequestStatus.completed: return 'Completed';
      case RequestStatus.declined:  return 'Declined';
      case RequestStatus.withdrawn: return 'Withdrawn';
    }
  }

  static Color _badgeColor(RequestStatus s) {
    switch (s) {
      case RequestStatus.completed: return AppColors.success;
      case RequestStatus.declined:  return AppColors.danger;
      case RequestStatus.withdrawn: return AppColors.inkMuted;
      default:                      return AppColors.maroon;
    }
  }
}

class _MissingRequestScaffold extends StatelessWidget {
  const _MissingRequestScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const AppHeader(title: 'Receiver Status'),
            Expanded(
              child: Center(
                child: Text(
                  'Request no longer available.',
                  style: AppText.body(color: AppColors.inkMuted),
                ),
              ),
            ),
          ],
        ),
      );
}
