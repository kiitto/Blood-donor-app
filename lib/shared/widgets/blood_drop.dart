import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A hand-painted teardrop — no bitmap, no emoji. Used for logo + accent marks.
class BloodDrop extends StatelessWidget {
  final double size;
  final Color color;
  final bool outlined;
  const BloodDrop({
    super.key,
    this.size = 24,
    this.color = AppColors.red,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _DropPainter(color: color, outlined: outlined),
      );
}

class _DropPainter extends CustomPainter {
  final Color color;
  final bool outlined;
  _DropPainter({required this.color, required this.outlined});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Teardrop: sharp point on top, circular belly at bottom.
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.5, h * 0.22, w, h * 0.4, w, h * 0.66);
    path.arcToPoint(
      Offset(0, h * 0.66),
      radius: Radius.circular(w * 0.5),
      clockwise: false,
    );
    path.cubicTo(0, h * 0.4, w * 0.5, h * 0.22, w * 0.5, 0);
    path.close();

    if (outlined) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      canvas.drawPath(path, Paint()..color = color);
      // Tiny highlight notch — subtle, readable, not a glossy AI sheen.
      final highlight = Path()
        ..moveTo(w * 0.32, h * 0.55)
        ..arcToPoint(
          Offset(w * 0.32, h * 0.80),
          radius: Radius.circular(w * 0.12),
          clockwise: false,
        )
        ..close();
      canvas.drawPath(
        highlight,
        Paint()..color = Colors.white.withOpacity(0.22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DropPainter old) =>
      old.color != color || old.outlined != outlined;
}

/// Decorative quarter-circle blooms for backgrounds, positioned in corners.
/// Used in splash + auth layouts to echo the mockup.
class CornerBloomPainter extends CustomPainter {
  final Color color;
  final Color colorDeep;
  final double opacity;
  CornerBloomPainter({
    required this.color,
    required this.colorDeep,
    this.opacity = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-left large bloom
    canvas.drawCircle(
      Offset(-w * 0.05, -h * 0.02),
      w * 0.42,
      Paint()..color = colorDeep.withOpacity(opacity),
    );
    // Top-right small dot
    canvas.drawCircle(
      Offset(w * 0.92, h * 0.05),
      w * 0.08,
      Paint()..color = color.withOpacity(opacity),
    );
    // Bottom-left small dot
    canvas.drawCircle(
      Offset(w * 0.12, h * 0.95),
      w * 0.06,
      Paint()..color = color.withOpacity(opacity),
    );
    // Bottom-right large bloom
    canvas.drawCircle(
      Offset(w * 1.02, h * 0.96),
      w * 0.36,
      Paint()..color = colorDeep.withOpacity(opacity),
    );
  }

  @override
  bool shouldRepaint(covariant CornerBloomPainter old) =>
      old.color != color || old.colorDeep != colorDeep || old.opacity != opacity;
}
