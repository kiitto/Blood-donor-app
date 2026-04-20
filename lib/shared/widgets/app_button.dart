import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonKind { primary, onDark, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool expand;
  final bool loading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.expand = true,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final palette = _palette(kind, enabled: enabled);

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: palette.fg,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: palette.fg),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: AppText.button(color: palette.fg).copyWith(letterSpacing: 1.2),
        ),
      ],
    );

    return Material(
      color: palette.bg,
      shape: palette.border == null
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
            )
          : RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              side: palette.border!,
            ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  _ButtonPalette _palette(AppButtonKind k, {required bool enabled}) {
    if (!enabled) {
      return const _ButtonPalette(
        bg: AppColors.surfaceSunken,
        fg: AppColors.inkFaint,
      );
    }
    switch (k) {
      case AppButtonKind.primary:
        return const _ButtonPalette(bg: AppColors.maroon, fg: AppColors.onMaroon);
      case AppButtonKind.onDark:
        return const _ButtonPalette(bg: AppColors.surface, fg: AppColors.maroon);
      case AppButtonKind.outline:
        return const _ButtonPalette(
          bg: Colors.transparent,
          fg: AppColors.maroon,
          border: BorderSide(color: AppColors.maroon, width: 1.2),
        );
      case AppButtonKind.ghost:
        return const _ButtonPalette(
          bg: Colors.transparent,
          fg: AppColors.ink,
          border: BorderSide(color: AppColors.hairline, width: 1),
        );
      case AppButtonKind.danger:
        return const _ButtonPalette(bg: AppColors.danger, fg: AppColors.onMaroon);
    }
  }
}

class _ButtonPalette {
  final Color bg;
  final Color fg;
  final BorderSide? border;
  const _ButtonPalette({required this.bg, required this.fg, this.border});
}
