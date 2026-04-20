import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/password_strength.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/password_strength_indicator.dart';
import '../../state/auth_provider.dart';
import '_auth_layout.dart';
import 'profile_setup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  PasswordStrength _strength = PasswordStrength.empty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordStrengthCheck.isAcceptable(_password.text)) {
      _snack('Password too weak — mix upper, lower, digit, or symbol');
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final res = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (res.outcome) {
      case AuthOutcome.success:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(fromSignup: true),
          ),
          (_) => false,
        );
        break;
      case AuthOutcome.emailTaken:
        _snack('An account already exists for that email');
        break;
      default:
        _snack('Could not create account');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Sign Up',
      showBack: true,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DarkFormField(
              controller: _name,
              hint: 'Name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
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
              onChanged: (v) =>
                  setState(() => _strength = PasswordStrengthCheck.of(v)),
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
            PasswordStrengthIndicator(strength: _strength),
            const SizedBox(height: 22),
            AppButton(
              label: _submitting ? 'Creating account' : 'Create Account',
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
            'Already have an account?',
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onMaroon,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                side: BorderSide(color: AppColors.onMaroonMuted, width: 1),
              ),
            ),
            child: Text(
              'LOG IN',
              style: AppText.button(color: AppColors.onMaroon, size: 13)
                  .copyWith(letterSpacing: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}
