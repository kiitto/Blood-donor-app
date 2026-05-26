import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_button.dart';
import '_auth_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — tabbed screen letting the user pick Email or Phone reset.
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ResetMethod { email, phone }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ResetMethod _method = _ResetMethod.email;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Reset Password',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Method toggle ──────────────────────────────────────────────────
          _MethodToggle(
            current: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 28),

          // ── Content pane ───────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _method == _ResetMethod.email
                ? const _EmailResetPane(key: ValueKey('email'))
                : const _PhoneOtpPane(key: ValueKey('phone')),
          ),
        ],
      ),
      footer: const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle pill
// ─────────────────────────────────────────────────────────────────────────────

class _MethodToggle extends StatelessWidget {
  final _ResetMethod current;
  final ValueChanged<_ResetMethod> onChanged;
  const _MethodToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.12),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: AppColors.onMaroonMuted.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            label: 'Email link',
            icon: Icons.mail_outline_rounded,
            selected: current == _ResetMethod.email,
            onTap: () => onChanged(_ResetMethod.email),
          ),
          _Tab(
            label: 'Phone OTP',
            icon: Icons.phone_outlined,
            selected: current == _ResetMethod.phone,
            onTap: () => onChanged(_ResetMethod.phone),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.maroon : AppColors.onMaroonMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.button(
                  color: selected ? AppColors.maroon : AppColors.onMaroonMuted,
                  size: 12,
                ).copyWith(letterSpacing: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pane 1 — Email reset link
// ─────────────────────────────────────────────────────────────────────────────

class _EmailResetPane extends StatefulWidget {
  const _EmailResetPane({super.key});

  @override
  State<_EmailResetPane> createState() => _EmailResetPaneState();
}

enum _EmailState { idle, sending, sent, error }

class _EmailResetPaneState extends State<_EmailResetPane> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  _EmailState _state = _EmailState.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _state = _EmailState.sending;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _email.text.trim().toLowerCase())
          .timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _state = _EmailState.sent);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _EmailState.error;
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _EmailState.error;
        _errorMessage = 'Something went wrong — check your connection.';
      });
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'network-request-failed':
        return 'Network error — check your internet connection.';
      default:
        return 'Could not send reset email (${code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _EmailState.sent) {
      return _SuccessCard(
        icon: Icons.mark_email_read_outlined,
        headline: 'Check your inbox',
        body:
            'We sent a password reset link to\n${_email.text.trim()}.\n\nCheck your spam folder if it doesn\'t arrive in a minute.',
        onRetry: () => setState(() {
          _state = _EmailState.idle;
          _email.clear();
        }),
        retryLabel: 'Send to a different email',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the email you signed up with.\nWe\'ll send a secure reset link.',
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13.5),
          ),
          const SizedBox(height: 22),
          DarkFormField(
            controller: _email,
            hint: 'Your email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
            validator: Validators.email,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: _state == _EmailState.sending ? 'Sending' : 'Send reset link',
            kind: AppButtonKind.onDark,
            loading: _state == _EmailState.sending,
            onPressed: _state == _EmailState.sending ? null : _send,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pane 2 — Phone OTP (Firebase Phone Auth)
//
// Flow:
//   Step 1 → enter +91 number → verifyPhoneNumber()
//   Step 2 → enter 6-digit OTP → credential.signIn() → show reset password
//   Step 3 → set new password via updatePassword()
// ─────────────────────────────────────────────────────────────────────────────

enum _PhoneStep { enterNumber, enterOtp, setPassword, done }

class _PhoneOtpPane extends StatefulWidget {
  const _PhoneOtpPane({super.key});

  @override
  State<_PhoneOtpPane> createState() => _PhoneOtpPaneState();
}

class _PhoneOtpPaneState extends State<_PhoneOtpPane> {
  _PhoneStep _step = _PhoneStep.enterNumber;

  // Step 1
  final _phoneFormKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _sendingOtp = false;
  String? _phoneError;

  // Step 2
  final _otpFormKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  bool _verifyingOtp = false;
  String? _otpError;
  String? _verificationId;
  int? _resendToken;

  // Step 3
  final _pwFormKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;
  String? _pwError;

  UserCredential? _credential;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP ────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() {
      _sendingOtp = true;
      _phoneError = null;
    });

    final fullNumber = '+91${_phone.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-retrieval — sign in silently
        try {
          _credential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) setState(() => _step = _PhoneStep.setPassword);
        } catch (_) {
          // Fall through to manual OTP entry
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _sendingOtp = false;
          _phoneError = _mapPhoneError(e.code);
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _sendingOtp = false;
          _step = _PhoneStep.enterOtp;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    setState(() {
      _verifyingOtp = true;
      _otpError = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text.trim(),
      );
      _credential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() => _step = _PhoneStep.setPassword);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _otpError = _mapOtpError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _otpError = 'Verification failed — try again.';
      });
    }
  }

  // ── Step 3: Set new password ───────────────────────────────────────────────

  Future<void> _savePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _pwError = 'Passwords do not match.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _pwError = null;
    });
    try {
      await _credential!.user!
          .updatePassword(_newPassword.text)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _step = _PhoneStep.done);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _pwError = e.code == 'weak-password'
            ? 'Password is too weak — mix upper, lower, digits, symbols.'
            : 'Could not update password (${e.code}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _pwError = 'Something went wrong — check your connection.';
      });
    }
  }

  String _mapPhoneError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Enter a valid 10-digit Indian mobile number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'quota-exceeded':
        return 'SMS quota exceeded — try the email option.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Could not send OTP (${code}).';
    }
  }

  String _mapOtpError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Incorrect code — double-check the SMS and try again.';
      case 'session-expired':
        return 'OTP expired. Go back and request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      default:
        return 'Verification failed (${code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _PhoneStep.enterNumber:
        return _buildEnterNumber();
      case _PhoneStep.enterOtp:
        return _buildEnterOtp();
      case _PhoneStep.setPassword:
        return _buildSetPassword();
      case _PhoneStep.done:
        return _SuccessCard(
          icon: Icons.lock_open_rounded,
          headline: 'Password updated!',
          body: 'Your new password is set. Go back to login and sign in.',
          onRetry: () => Navigator.of(context).pop(),
          retryLabel: 'Back to Login',
        );
    }
  }

  // ── UI: Step 1 ─────────────────────────────────────────────────────────────

  Widget _buildEnterNumber() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your registered mobile number.\nWe\'ll send a one-time password via SMS.',
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13.5),
          ),
          const SizedBox(height: 22),
          DarkFormField(
            controller: _phone,
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _sendOtp(),
            validator: Validators.phone,
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _phoneError!),
          ],
          const SizedBox(height: 10),
          Text(
            'Standard SMS charges may apply.',
            style: AppText.caption(color: AppColors.onMaroonMuted, size: 11.5),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _sendingOtp ? 'Sending OTP' : 'Send OTP',
            kind: AppButtonKind.onDark,
            loading: _sendingOtp,
            onPressed: _sendingOtp ? null : _sendOtp,
          ),
        ],
      ),
    );
  }

  // ── UI: Step 2 ─────────────────────────────────────────────────────────────

  Widget _buildEnterOtp() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step indicator
          _StepIndicator(currentStep: 1, totalSteps: 2),
          const SizedBox(height: 20),
          Text(
            'Enter the 6-digit OTP sent to\n+91 ${_phone.text.trim()}',
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13.5),
          ),
          const SizedBox(height: 22),
          DarkFormField(
            controller: _otp,
            hint: '6-digit code',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyOtp(),
            validator: (v) {
              if ((v ?? '').trim().length != 6) return 'Enter the 6-digit OTP';
              return null;
            },
          ),
          if (_otpError != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _otpError!),
          ],
          const SizedBox(height: 14),
          // Resend row
          Row(
            children: [
              Text(
                "Didn't receive it?",
                style: AppText.caption(color: AppColors.onMaroonMuted, size: 12),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _step = _PhoneStep.enterNumber;
                    _otp.clear();
                    _otpError = null;
                  });
                },
                child: Text(
                  'Resend',
                  style: AppText.caption(
                          color: AppColors.onMaroon, size: 12)
                      .copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.onMaroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _verifyingOtp ? 'Verifying' : 'Verify OTP',
            kind: AppButtonKind.onDark,
            loading: _verifyingOtp,
            onPressed: _verifyingOtp ? null : _verifyOtp,
          ),
        ],
      ),
    );
  }

  // ── UI: Step 3 ─────────────────────────────────────────────────────────────

  Widget _buildSetPassword() {
    return Form(
      key: _pwFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(currentStep: 2, totalSteps: 2),
          const SizedBox(height: 20),
          Text(
            'Phone verified. Choose a strong new password.',
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13.5),
          ),
          const SizedBox(height: 22),
          DarkFormField(
            controller: _newPassword,
            hint: 'New password',
            obscure: _obscureNew,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if ((v ?? '').length < 8) return 'At least 8 characters';
              return null;
            },
            suffix: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.inkMuted,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 14),
          DarkFormField(
            controller: _confirmPassword,
            hint: 'Confirm new password',
            obscure: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _savePassword(),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Confirm your password';
              return null;
            },
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.inkMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          if (_pwError != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _pwError!),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: _savingPassword ? 'Saving' : 'Set new password',
            kind: AppButtonKind.onDark,
            loading: _savingPassword,
            onPressed: _savingPassword ? null : _savePassword,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final done = i < currentStep;
        final active = i == currentStep - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: done || active
                    ? AppColors.onMaroon
                    : AppColors.onMaroonMuted.withOpacity(0.3),
                borderRadius: const BorderRadius.all(Radius.circular(1)),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.15),
        border: Border.all(color: AppColors.red.withOpacity(0.5)),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 15, color: Color(0xFFFFCDD2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppText.caption(color: const Color(0xFFFFCDD2), size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;
  final VoidCallback onRetry;
  final String retryLabel;
  const _SuccessCard({
    required this.icon,
    required this.headline,
    required this.body,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.15),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            border: Border.all(color: AppColors.onMaroonMuted.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: AppColors.onMaroon),
        ),
        const SizedBox(height: 20),
        Text(headline,
            style: AppText.headline(color: AppColors.onMaroon, size: 24)),
        const SizedBox(height: 10),
        Text(body,
            style: AppText.body(color: AppColors.onMaroonMuted, size: 13.5)),
        const SizedBox(height: 28),
        AppButton(
          label: retryLabel,
          kind: AppButtonKind.onDark,
          onPressed: onRetry,
        ),
      ],
    );
  }
}