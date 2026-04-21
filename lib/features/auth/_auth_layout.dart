import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/blood_drop.dart';

/// Shared maroon layout for auth screens. Keeps splash → login → signup
/// visually consistent: decorative corner dots, centered editorial title,
/// slot for form, and a footer row for alt-path links.
class AuthLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget footer;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.child,
    required this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.maroon,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _AuthBackdropPainter()),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: showBack
                              ? IconButton(
                                  onPressed: () => Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                      size: 18, color: AppColors.onMaroon),
                                )
                              : null,
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: const BloodDrop(size: 22, color: AppColors.onMaroon),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                title,
                                textAlign: TextAlign.start,
                                style: AppText.display(
                                        size: 38, color: AppColors.onMaroon)
                                    .copyWith(letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 28),
                              child,
                              const SizedBox(height: 20),
                              footer,
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(-w * 0.18, -h * 0.08),
      w * 0.55,
      Paint()..color = AppColors.maroonDeep,
    );
    canvas.drawCircle(
      Offset(w * 1.05, h * 1.02),
      w * 0.55,
      Paint()..color = AppColors.maroonDeep,
    );
    canvas.drawCircle(
      Offset(w * 0.94, h * 0.06),
      w * 0.05,
      Paint()..color = AppColors.red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// TextFormField styled for maroon backgrounds: white-filled box, hairline
/// border, compact density. No AI glow, no floating label animations.
class DarkFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const DarkFormField({
    super.key,
    this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      cursorColor: AppColors.maroon,
      cursorWidth: 1.4,
      style: AppText.body(color: AppColors.ink, size: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(color: AppColors.inkFaint, size: 15),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffix,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.onMaroon, width: 1.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.red, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.red, width: 1.2),
        ),
        errorStyle: AppText.caption(color: Color(0xFFFFCDD2), size: 11.5),
      ),
    );
  }
}
