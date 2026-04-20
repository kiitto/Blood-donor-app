import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Flat card with a 1px hairline — no shadow, no rounded-corner generic card
/// look. Used consistently across lists so the surface feels intentional.
class CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? background;
  final Color? borderColor;

  const CardShell({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(2)),
      side: BorderSide(color: borderColor ?? AppColors.hairline, width: 1),
    );
    return Material(
      color: background ?? AppColors.surface,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
