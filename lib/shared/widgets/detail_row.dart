import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// One line of key/value in a compact receipt-style grid.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(
                label.toUpperCase(),
                style: AppText.label(color: AppColors.inkMuted, size: 10.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: strong
                    ? AppText.bodyStrong(color: valueColor ?? AppColors.ink)
                    : AppText.body(color: valueColor ?? AppColors.ink),
              ),
            ),
          ],
        ),
      );
}

class Hairline extends StatelessWidget {
  final EdgeInsets margin;
  const Hairline({super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: margin,
        color: AppColors.hairline,
      );
}
