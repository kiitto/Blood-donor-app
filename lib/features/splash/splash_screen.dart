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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: const BloodDrop(size: 28, color: AppColors.onMaroon),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Blood Donor',
                    style: AppText.display(size: 44, color: AppColors.ink)
                        .copyWith(height: 1.0),
                  ),
                  Text(
                    '& Receiver.',
                    style: AppText.display(size: 44, color: AppColors.maroon)
                        .copyWith(height: 1.05),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Be someone's lifeline today.",
                    style: AppText.body(color: AppColors.inkMuted, size: 15),
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

    // Single deep bloom in the top-right quadrant — enough silhouette to
    // feel intentional without the five-circle AI-decor cluster.
    canvas.drawCircle(
      Offset(w * 1.05, -h * 0.06),
      w * 0.55,
      Paint()..color = AppColors.maroonDeep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
