import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'blood_drop.dart';

/// Thin top strip with a back button (optional) on the left, an eyebrow label
/// + title in the middle, and the blood-drop logomark on the right. Used as an
/// alternative to AppBar when we want the title to sit on a maroon backdrop.
class AppHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Color background;
  final Color foreground;
  final Widget? trailing;

  const AppHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.background = AppColors.maroon,
    this.foreground = AppColors.onMaroon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: background,
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: showBack
                ? InkResponse(
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    radius: 22,
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: foreground),
                  )
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppText.label(
                        color: foreground.withOpacity(0.7), size: 10),
                  ),
                Text(
                  title,
                  style: AppText.headline(color: foreground, size: 22),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing! else const _LogoMark(),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: BloodDrop(size: 24, color: AppColors.onMaroon),
        ),
      );
}
