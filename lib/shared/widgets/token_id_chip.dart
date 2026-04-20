import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Monospace pill for token IDs (DNR-20260420-001). Keeps the visual rhythm of
/// dates and IDs tight so scanning a list is quick.
class TokenIdChip extends StatelessWidget {
  final String id;
  final bool onDark;
  const TokenIdChip({super.key, required this.id, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final bg = onDark ? AppColors.onMaroonMuted.withOpacity(0.18) : AppColors.surfaceMuted;
    final fg = onDark ? AppColors.onMaroon : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
      child: Text(id, style: AppText.monoTag(color: fg)),
    );
  }
}
