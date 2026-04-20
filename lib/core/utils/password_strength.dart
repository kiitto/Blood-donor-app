import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PasswordStrength { empty, weak, medium, strong }

extension PasswordStrengthMeta on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.empty:  return '';
      case PasswordStrength.weak:   return 'Weak';
      case PasswordStrength.medium: return 'Medium';
      case PasswordStrength.strong: return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:  return AppColors.hairline;
      case PasswordStrength.weak:   return AppColors.danger;
      case PasswordStrength.medium: return AppColors.warning;
      case PasswordStrength.strong: return AppColors.success;
    }
  }

  /// 0.0–1.0 fill for the meter.
  double get fill {
    switch (this) {
      case PasswordStrength.empty:  return 0.0;
      case PasswordStrength.weak:   return 0.33;
      case PasswordStrength.medium: return 0.66;
      case PasswordStrength.strong: return 1.0;
    }
  }
}

class PasswordStrengthCheck {
  PasswordStrengthCheck._();

  static PasswordStrength of(String value) {
    if (value.isEmpty) return PasswordStrength.empty;
    if (value.length < 8) return PasswordStrength.weak;

    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSymbol = RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:,.<>?/\\|`~"]').hasMatch(value);

    final classes =
        (hasLower ? 1 : 0) + (hasUpper ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSymbol ? 1 : 0);

    if (classes <= 1) return PasswordStrength.weak;
    if (classes == 2) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Minimum bar to sign up: medium.
  static bool isAcceptable(String value) =>
      of(value).index >= PasswordStrength.medium.index;
}
