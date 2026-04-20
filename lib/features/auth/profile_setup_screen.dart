import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/confirm_exit_dialog.dart';
import '../../shared/widgets/location_field.dart';
import '../../state/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool fromSignup;
  const ProfileSetupScreen({super.key, this.fromSignup = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _location = TextEditingController();
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().current;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
      _dob.text = user.dob;
      _location.text = user.location;
    }
    for (final c in [_name, _phone, _dob, _location]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dob.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _parseDate(_dob.text) ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.maroon,
                onPrimary: AppColors.onMaroon,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dob.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  DateTime? _parseDate(String s) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().completeProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          dob: _dob.text.trim(),
          location: _location.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    return confirmDiscardChanges(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allow = await _onWillPop();
        if (allow && mounted) Navigator.of(context).pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.maroon,
          body: Column(
            children: [
              AppHeader(
                eyebrow: 'Profile',
                title: 'Create Profile',
                showBack: !widget.fromSignup,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Your details',
                              style: AppText.headline(size: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We prefill these on donor and receiver forms — you can always edit later.',
                              style: AppText.body(color: AppColors.inkMuted, size: 13.5),
                            ),
                            const SizedBox(height: 26),
                            AppTextField(
                              label: 'Full name',
                              hint: 'Type your name',
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.name,
                            ),
                            const SizedBox(height: 20),
                            LocationField(
                              controller: _location,
                              label: 'Location',
                              hint: 'City, State',
                              validator: (v) =>
                                  Validators.required(v, label: 'Location'),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Phone',
                              hint: '10-digit mobile',
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              prefixText: '+91  ',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Date of birth',
                              hint: 'dd/mm/yyyy',
                              controller: _dob,
                              readOnly: true,
                              onTap: _pickDob,
                              trailing: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                              validator: (v) => Validators.required(v, label: 'DOB'),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Email',
                              hint: '',
                              initialValue:
                                  context.read<AuthProvider>().current?.email ?? '',
                              readOnly: true,
                            ),
                            const SizedBox(height: 32),
                            AppButton(
                              label: _saving ? 'Saving' : 'Save',
                              onPressed: _saving ? null : _save,
                              loading: _saving,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
