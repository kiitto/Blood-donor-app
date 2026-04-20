import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/password_strength.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) {
      return const SizedBox(height: 20);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(1)),
              child: Stack(
                children: [
                  Container(height: 3, color: AppColors.hairline),
                  FractionallySizedBox(
                    widthFactor: strength.fill,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      color: strength.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            strength.label,
            style: AppText.caption(color: strength.color, size: 11.5)
                .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
