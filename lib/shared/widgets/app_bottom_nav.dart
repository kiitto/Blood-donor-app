import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum BottomNavAction { donate, profile, receive }

class AppBottomNav extends StatelessWidget {
  final void Function(BottomNavAction action) onTap;
  final BottomNavAction? current;
  const AppBottomNav({super.key, required this.onTap, this.current});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline, width: 1)),
      ),
      padding: EdgeInsets.only(top: 8, bottom: bottom + 8, left: 8, right: 8),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              label: 'Donate',
              icon: Icons.volunteer_activism_outlined,
              active: current == BottomNavAction.donate,
              onTap: () => onTap(BottomNavAction.donate),
            ),
          ),
          Expanded(
            child: _NavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              active: current == BottomNavAction.profile,
              onTap: () => onTap(BottomNavAction.profile),
              emphasized: true,
            ),
          ),
          Expanded(
            child: _NavItem(
              label: 'Receive',
              icon: Icons.bloodtype_outlined,
              active: current == BottomNavAction.receive,
              onTap: () => onTap(BottomNavAction.receive),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool emphasized;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.maroon : AppColors.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: emphasized ? 2 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(emphasized ? 9 : 0),
              decoration: emphasized
                  ? BoxDecoration(
                      color: active ? AppColors.maroon : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                icon,
                color: emphasized
                    ? (active ? AppColors.onMaroon : AppColors.ink)
                    : color,
                size: emphasized ? 20 : 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.caption(color: color, size: 11)
                  .copyWith(fontWeight: active ? FontWeight.w600 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
