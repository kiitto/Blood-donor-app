import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/donor_model.dart';
import '../../data/models/receiver_model.dart';
import '../../data/models/request_model.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/card_shell.dart';
import '../../shared/widgets/detail_row.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/token_id_chip.dart';
import '../../state/receiver_provider.dart';
import '../../state/request_provider.dart';
import 'donor_status_screen.dart';

class DonorTokenRequestsScreen extends StatelessWidget {
  final DonorToken token;
  const DonorTokenRequestsScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestProvider>().forDonorToken(token.id);
    final receiverProv = context.watch<ReceiverProvider>();

    // Divide: active ones to action, terminal ones for history.
    final pending = requests.where((r) => r.status == RequestStatus.pending).toList();
    final accepted = requests.firstWhereOrNull(
      (r) =>
          r.status == RequestStatus.accepted ||
          r.status == RequestStatus.contacted ||
          r.status == RequestStatus.arranged,
    );
    final closed = requests.where((r) => r.status.isTerminal).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppHeader(
            eyebrow: 'Donor',
            title: 'Incoming Requests',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              children: [
                _TokenCard(token: token),
                const SizedBox(height: 26),
                if (token.closed && accepted != null) ...[
                  _SectionLabel('In progress'),
                  const SizedBox(height: 10),
                  _AcceptedCard(
                    request: accepted,
                    receiver: receiverProv.byId(accepted.receiverTokenId),
                    onTrack: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DonorStatusScreen(requestId: accepted.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (pending.isEmpty && accepted == null && closed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyState(
                      headline: 'No requests yet',
                      body: 'When receivers send requests to this token, '
                          'they show up here.',
                    ),
                  ),
                if (pending.isNotEmpty && !token.closed) ...[
                  _SectionLabel('Pending your response'),
                  const SizedBox(height: 10),
                  ...pending.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PendingRequestCard(
                          request: r,
                          receiver: receiverProv.byId(r.receiverTokenId),
                          onAccept: () async {
                            await context
                                .read<RequestProvider>()
                                .advance(r.id, RequestStatus.accepted);
                          },
                          onDecline: () async {
                            await context.read<RequestProvider>().decline(r.id);
                          },
                        ),
                      )),
                ],
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionLabel('History'),
                  const SizedBox(height: 10),
                  ...closed.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ClosedRequestCard(
                          request: r,
                          receiver: receiverProv.byId(r.receiverTokenId),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppText.label());
}

class _TokenCard extends StatelessWidget {
  final DonorToken token;
  const _TokenCard({required this.token});
  @override
  Widget build(BuildContext context) => CardShell(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TokenIdChip(id: token.id),
                const Spacer(),
                _GroupPill(group: token.bloodGroup),
              ],
            ),
            const SizedBox(height: 12),
            Text(token.name, style: AppText.title(size: 19)),
            const SizedBox(height: 4),
            Text(token.location,
                style: AppText.body(color: AppColors.inkMuted, size: 13)),
            if (token.closed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: AppColors.surfaceMuted,
                child: Text(
                  'Closed to new requests — one accepted',
                  style: AppText.caption(color: AppColors.ink),
                ),
              ),
            ],
          ],
        ),
      );
}

class _GroupPill extends StatelessWidget {
  final String group;
  const _GroupPill({required this.group});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: AppColors.maroon,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        child: Text(
          group,
          style: AppText.bodyStrong(color: AppColors.onMaroon, size: 12.5)
              .copyWith(letterSpacing: 0.4),
        ),
      );
}

class _PendingRequestCard extends StatelessWidget {
  final BloodRequest request;
  final ReceiverToken? receiver;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _PendingRequestCard({
    required this.request,
    required this.receiver,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TokenIdChip(id: request.id),
              const Spacer(),
              Text(
                DateFormat('dd MMM, HH:mm').format(request.createdAt),
                style: AppText.caption(color: AppColors.inkMuted, size: 11.5),
              ),
            ],
          ),
          const Hairline(margin: EdgeInsets.symmetric(vertical: 12)),
          DetailRow(label: 'Patient', value: receiver?.name ?? '—', strong: true),
          DetailRow(label: 'Cause', value: receiver?.displayCause ?? '—'),
          DetailRow(label: 'Units', value: (receiver?.unitsNeeded ?? 0).toString()),
          DetailRow(label: 'Contact', value: receiver == null ? '—' : '+91 ${receiver!.phone}'),
          DetailRow(label: 'Location', value: receiver?.location ?? '—'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Decline',
                  kind: AppButtonKind.ghost,
                  onPressed: onDecline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Accept',
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptedCard extends StatelessWidget {
  final BloodRequest request;
  final ReceiverToken? receiver;
  final VoidCallback onTrack;
  const _AcceptedCard({
    required this.request,
    required this.receiver,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) => CardShell(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TokenIdChip(id: request.id),
                const Spacer(),
                Text(
                  _statusLabel(request.status),
                  style: AppText.caption(color: AppColors.maroon)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Hairline(margin: EdgeInsets.symmetric(vertical: 12)),
            DetailRow(label: 'Patient', value: receiver?.name ?? '—', strong: true),
            DetailRow(label: 'Cause', value: receiver?.displayCause ?? '—'),
            DetailRow(label: 'Contact', value: receiver == null ? '—' : '+91 ${receiver!.phone}'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Track donation',
              kind: AppButtonKind.outline,
              onPressed: onTrack,
            ),
          ],
        ),
      );
}

class _ClosedRequestCard extends StatelessWidget {
  final BloodRequest request;
  final ReceiverToken? receiver;
  const _ClosedRequestCard({required this.request, required this.receiver});

  @override
  Widget build(BuildContext context) {
    final color = request.status == RequestStatus.completed
        ? AppColors.success
        : AppColors.inkMuted;
    return CardShell(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receiver?.name ?? 'Patient',
                    style: AppText.bodyStrong(size: 14)),
                const SizedBox(height: 2),
                Text(
                  '${_statusLabel(request.status)} · '
                  '${DateFormat('dd MMM').format(request.updatedAt)}',
                  style: AppText.caption(color: color),
                ),
              ],
            ),
          ),
          TokenIdChip(id: request.id),
        ],
      ),
    );
  }
}

String _statusLabel(RequestStatus s) {
  switch (s) {
    case RequestStatus.pending:   return 'Awaiting response';
    case RequestStatus.accepted:  return 'Accepted';
    case RequestStatus.contacted: return 'Patient contacted';
    case RequestStatus.arranged:  return 'Blood arranged';
    case RequestStatus.completed: return 'Donated';
    case RequestStatus.declined:  return 'Declined';
    case RequestStatus.withdrawn: return 'Withdrawn';
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
