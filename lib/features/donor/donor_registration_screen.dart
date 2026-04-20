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
import '../../shared/widgets/blood_group_selector.dart';
import '../../shared/widgets/confirm_exit_dialog.dart';
import '../../shared/widgets/location_field.dart';
import '../../shared/widgets/token_id_chip.dart';
import '../../state/auth_provider.dart';
import '../../state/donor_provider.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({super.key});

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _lastDonation = TextEditingController();
  String? _bloodGroup;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().current;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
      _location.text = user.location;
    }
    for (final c in [_name, _phone, _location, _lastDonation]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    _lastDonation.dispose();
    super.dispose();
  }

  Future<void> _pickLastDonation() async {
    final now = DateTime.now();
    final initial =
        _parseDate(_lastDonation.text) ?? now.subtract(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
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
      _lastDonation.text = DateFormat('dd/MM/yyyy').format(picked);
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
    final groupOk = _bloodGroup != null;
    final formOk = _formKey.currentState!.validate();
    if (!groupOk) {
      _snack('Pick a blood group');
      return;
    }
    if (!formOk) return;

    setState(() => _saving = true);
    final user = context.read<AuthProvider>().current!;
    final token = await context.read<DonorProvider>().create(
          ownerEmail: user.email,
          name: _name.text.trim(),
          bloodGroup: _bloodGroup!,
          location: _location.text.trim(),
          phone: _phone.text.trim(),
          lastDonationDate: _lastDonation.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    await _showSuccess(token.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showSuccess(String tokenId) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donor token created',
                  style: AppText.headline(size: 22)),
              const SizedBox(height: 6),
              Text(
                'Receivers nearby will see this token on their search screen.',
                style: AppText.body(color: AppColors.inkMuted, size: 13),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('ID', style: AppText.label()),
                  const SizedBox(width: 10),
                  TokenIdChip(id: tokenId),
                ],
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
        ),
        child: Scaffold(
          backgroundColor: AppColors.maroon,
          body: Column(
            children: [
              const AppHeader(eyebrow: 'Register', title: 'Donor Details'),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: AppColors.surface),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "You're volunteering to donate",
                              style: AppText.headline(size: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can register on behalf of someone else — just fill their details.',
                              style: AppText.body(
                                  color: AppColors.inkMuted, size: 13.5),
                            ),
                            const SizedBox(height: 26),
                            AppTextField(
                              label: 'Full name',
                              hint: 'Type donor name',
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.name,
                            ),
                            const SizedBox(height: 20),
                            LocationField(
                              controller: _location,
                              label: 'Area',
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
                              label: 'Last donation date',
                              hint: 'dd/mm/yyyy (optional)',
                              controller: _lastDonation,
                              readOnly: true,
                              onTap: _pickLastDonation,
                              trailing: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            BloodGroupSelector(
                              value: _bloodGroup,
                              onChanged: (g) {
                                _dirty = true;
                                setState(() => _bloodGroup = g);
                              },
                              label: 'Blood group',
                            ),
                            const SizedBox(height: 34),
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
