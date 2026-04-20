import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum StatusMarkState { done, current, pending }

class StatusStep {
  final String label;
  final StatusMarkState state;
  const StatusStep(this.label, this.state);
}

class StatusTracker extends StatelessWidget {
  final List<StatusStep> steps;
  const StatusTracker({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _Marker(state: step.state),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        color: step.state == StatusMarkState.done
                            ? AppColors.maroon
                            : AppColors.hairline,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
                child: Text(
                  step.label,
                  style: AppText.body(
                    color: step.state == StatusMarkState.pending
                        ? AppColors.inkFaint
                        : AppColors.ink,
                  ).copyWith(
                    fontWeight: step.state == StatusMarkState.current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Marker extends StatelessWidget {
  final StatusMarkState state;
  const _Marker({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StatusMarkState.done:
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.maroon,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: AppColors.onMaroon),
        );
      case StatusMarkState.current:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.maroon, width: 2),
          ),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.maroon,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case StatusMarkState.pending:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairlineStrong, width: 1),
          ),
        );
    }
  }
}
