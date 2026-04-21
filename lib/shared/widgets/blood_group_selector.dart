import 'package:flutter/material.dart';

import '../../core/constants/blood_groups.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BloodGroupSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;
  const BloodGroupSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Blood Group',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.caption(color: AppColors.inkMuted, size: 12)
                .copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BloodGroups.all.map((g) {
            final selected = g == value;
            return _Chip(
              label: g,
              selected: selected,
              onTap: () => onChanged(g),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.maroon : Colors.transparent;
    final fg = selected ? AppColors.onMaroon : AppColors.maroon;
    final border = selected ? AppColors.maroon : AppColors.maroon.withOpacity(0.35);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppText.bodyStrong(color: fg, size: 13).copyWith(letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}
