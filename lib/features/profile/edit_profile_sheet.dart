import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/location_field.dart';
import '../../state/auth_provider.dart';

Future<void> showEditProfileSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
    ),
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _location;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().current!;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone);
    _dob = TextEditingController(text: user.dob);
    _location = TextEditingController(text: user.location);
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
    DateTime initial;
    try {
      initial = DateFormat('dd/MM/yyyy').parseStrict(_dob.text);
    } catch (_) {
      initial = DateTime(now.year - 25);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 16, now.month, now.day),
    );
    if (picked != null) {
      _dob.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().editProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          dob: _dob.text.trim(),
          location: _location.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 3,
                  color: AppColors.hairlineStrong,
                ),
              ),
              const SizedBox(height: 18),
              Text('Edit profile', style: AppText.headline(size: 22)),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Full name',
                hint: 'Type your name',
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
              ),
              const SizedBox(height: 18),
              LocationField(
                controller: _location,
                validator: (v) => Validators.required(v, label: 'Location'),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
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
              const SizedBox(height: 28),
              AppButton(
                label: _saving ? 'Saving' : 'Save changes',
                onPressed: _saving ? null : _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
