import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Editorial form field: uppercase label above, hairline underline, hint inside.
/// Deliberately not a boxed Material TextField — it sets this app apart from
/// the generic Material look.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscure;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? prefixText;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.obscure = false,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.prefixText,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption(color: AppColors.inkMuted, size: 12)
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  initialValue: initialValue,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  validator: validator,
                  onChanged: onChanged,
                  obscureText: obscure,
                  readOnly: readOnly,
                  onTap: onTap,
                  maxLines: obscure ? 1 : maxLines,
                  textCapitalization: textCapitalization,
                  focusNode: focusNode,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onSubmitted,
                  style: AppText.body(size: 16),
                  cursorColor: AppColors.maroon,
                  cursorWidth: 1.4,
                  decoration: InputDecoration(
                    hintText: hint,
                    prefixText: prefixText,
                    isDense: true,
                  ),
                ),
              ),
              if (trailing != null) Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: trailing,
              ),
            ],
          ),
        ],
      );
}
