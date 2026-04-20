import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../state/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '_auth_layout.dart';
import 'profile_setup_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final res = await auth.logIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (res.outcome) {
      case AuthOutcome.success:
        final next = auth.needsProfileSetup
            ? const ProfileSetupScreen(fromSignup: true)
            : const DashboardScreen();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next),
          (_) => false,
        );
        break;
      case AuthOutcome.unknownEmail:
        _snack('No account found for that email');
        break;
      case AuthOutcome.invalidCredentials:
        _snack('Incorrect password');
        break;
      default:
        _snack('Something went wrong');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Login',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DarkFormField(
              controller: _email,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            DarkFormField(
              controller: _password,
              hint: 'Password',
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              label: _submitting ? 'Signing in' : 'Log In',
              kind: AppButtonKind.onDark,
              onPressed: _submitting ? null : _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
      footer: Column(
        children: [
          Text(
            "Don't have an account?",
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onMaroon,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                side: BorderSide(color: AppColors.onMaroonMuted, width: 1),
              ),
            ),
            child: Text(
              'SIGN UP',
              style: AppText.button(color: AppColors.onMaroon, size: 13)
                  .copyWith(letterSpacing: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}
