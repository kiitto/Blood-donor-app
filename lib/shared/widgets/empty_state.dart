import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'blood_drop.dart';

/// Editorial empty state — a single faint drop + a short headline + body.
/// No illustration clip-art, no "generic AI" decoration.
class EmptyState extends StatelessWidget {
  final String headline;
  final String body;
  final Widget? action;
  final Color drop;
  const EmptyState({
    super.key,
    required this.headline,
    required this.body,
    this.action,
    this.drop = AppColors.hairlineStrong,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BloodDrop(size: 34, color: drop, outlined: true),
                const SizedBox(height: 18),
                Text(
                  headline,
                  style: AppText.headline(size: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: AppText.body(color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  action!,
                ],
              ],
            ),
          ),
        ),
      );
}
