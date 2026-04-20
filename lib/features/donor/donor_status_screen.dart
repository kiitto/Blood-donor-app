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

class DonorStatusScreen extends StatelessWidget {
  final String requestId;
  const DonorStatusScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final reqProv = context.watch<RequestProvider>();
    final donorProv = context.watch<DonorProvider>();
    final rcvProv = context.watch<ReceiverProvider>();

    final req = reqProv.byId(requestId);
    if (req == null) {
      return const _MissingRequestScaffold();
    }
    final donor = donorProv.byId(req.donorTokenId);
    final receiver = rcvProv.byId(req.receiverTokenId);

    final steps = <StatusStep>[
      StatusStep('Request accepted', _stateFor(req.status, RequestStatus.accepted)),
      StatusStep('Patient contacted', _stateFor(req.status, RequestStatus.contacted)),
      StatusStep('Blood arranged', _stateFor(req.status, RequestStatus.arranged)),
      StatusStep('Donated', _stateFor(req.status, RequestStatus.completed)),
    ];

    final next = _nextAction(req.status);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppHeader(
            eyebrow: 'Donor',
            title: 'Donor Status',
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
                          if (donor != null)
                            Text(donor.bloodGroup,
                                style: AppText.monoTag(color: AppColors.maroon)),
                        ],
                      ),
                      const Hairline(margin: EdgeInsets.symmetric(vertical: 12)),
                      DetailRow(
                        label: 'Patient',
                        value: receiver?.name ?? '—',
                        strong: true,
                      ),
                      DetailRow(
                        label: 'Phone',
                        value: receiver == null ? '—' : '+91 ${receiver.phone}',
                      ),
                      DetailRow(
                        label: 'Units',
                        value: receiver == null
                            ? '—'
                            : receiver.unitsNeeded.toString(),
                      ),
                      DetailRow(
                        label: 'Location',
                        value: receiver?.location ?? '—',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('PROGRESS', style: AppText.label()),
                const SizedBox(height: 14),
                StatusTracker(steps: steps),
                const SizedBox(height: 30),
                if (next != null)
                  AppButton(
                    label: next.label,
                    onPressed: () async {
                      await context
                          .read<RequestProvider>()
                          .advance(req.id, next.status);
                      if (next.status == RequestStatus.completed &&
                          context.mounted) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                if (req.status == RequestStatus.completed)
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: AppColors.surfaceMuted,
                    child: Text(
                      'This donation is complete. Thank you for saving a life.',
                      style: AppText.body(color: AppColors.success, size: 14)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static StatusMarkState _stateFor(RequestStatus current, RequestStatus step) {
    if (current.flowIndex >= step.flowIndex && step.flowIndex >= 0) {
      return current.flowIndex == step.flowIndex
          ? StatusMarkState.current
          : StatusMarkState.done;
    }
    return StatusMarkState.pending;
  }

  static _NextAction? _nextAction(RequestStatus s) {
    switch (s) {
      case RequestStatus.accepted:
        return _NextAction('Mark patient contacted', RequestStatus.contacted);
      case RequestStatus.contacted:
        return _NextAction('Mark blood arranged', RequestStatus.arranged);
      case RequestStatus.arranged:
        return _NextAction('Mark as completed', RequestStatus.completed);
      default:
        return null;
    }
  }
}

class _NextAction {
  final String label;
  final RequestStatus status;
  const _NextAction(this.label, this.status);
}

class _MissingRequestScaffold extends StatelessWidget {
  const _MissingRequestScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const AppHeader(title: 'Donor Status'),
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
