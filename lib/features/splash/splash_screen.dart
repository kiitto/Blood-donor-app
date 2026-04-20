import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/blood_drop.dart';
import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _advance();
  }

  Future<void> _advance() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Widget next;
    if (!auth.isSignedIn) {
      next = const LoginScreen();
    } else if (auth.needsProfileSetup) {
      next = const ProfileSetupScreen(fromSignup: true);
    } else {
      next = const DashboardScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _SplashBackdropPainter(),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                    child: const BloodDrop(size: 44, color: AppColors.onMaroon),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'BLOOD DONOR',
                    style: AppText.display(size: 30, color: AppColors.ink)
                        .copyWith(letterSpacing: 3.0, height: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RECEIVER',
                    style: AppText.display(size: 30, color: AppColors.ink)
                        .copyWith(letterSpacing: 3.0, height: 1.0),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Be someone's lifeline today",
                    style: AppText.body(color: AppColors.inkMuted, size: 14)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-left deep bloom
    canvas.drawCircle(
      Offset(-w * 0.12, -h * 0.02),
      w * 0.52,
      Paint()..color = AppColors.maroonDeep,
    );
    // Top-right medium dot
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.02),
      w * 0.12,
      Paint()..color = AppColors.maroon,
    );
    // Bottom dominant bloom
    canvas.drawCircle(
      Offset(w * 0.75, h * 1.05),
      w * 0.65,
      Paint()..color = AppColors.maroonDeep,
    );
    // Bottom-left medium dot
    canvas.drawCircle(
      Offset(w * 0.1, h * 0.92),
      w * 0.10,
      Paint()..color = AppColors.maroon,
    );
    // Tiny floater for balance
    canvas.drawCircle(
      Offset(w * 0.42, h * 0.88),
      w * 0.04,
      Paint()..color = AppColors.red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
