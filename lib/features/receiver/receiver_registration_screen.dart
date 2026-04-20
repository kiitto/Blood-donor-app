import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/cities.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/blood_group_selector.dart';
import '../../shared/widgets/confirm_exit_dialog.dart';
import '../../shared/widgets/location_field.dart';
import '../../state/auth_provider.dart';
import '../../state/receiver_provider.dart';
import 'search_donors_screen.dart';

class ReceiverRegistrationScreen extends StatefulWidget {
  const ReceiverRegistrationScreen({super.key});

  @override
  State<ReceiverRegistrationScreen> createState() =>
      _ReceiverRegistrationScreenState();
}

class _ReceiverRegistrationScreenState extends State<ReceiverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _units = TextEditingController(text: '1');
  final _causeOther = TextEditingController();
  String? _bloodGroup;
  String _cause = Causes.options.first;
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
    for (final c in [_name, _phone, _location, _units, _causeOther]) {
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
    _units.dispose();
    _causeOther.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_bloodGroup == null) {
      _snack('Pick a blood group');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_cause == 'Other' && _causeOther.text.trim().isEmpty) {
      _snack('Describe the cause');
      return;
    }

    setState(() => _saving = true);
    final user = context.read<AuthProvider>().current!;
    final token = await context.read<ReceiverProvider>().create(
          ownerEmail: user.email,
          name: _name.text.trim(),
          bloodGroup: _bloodGroup!,
          location: _location.text.trim(),
          phone: _phone.text.trim(),
          cause: _cause,
          causeOther: _causeOther.text.trim(),
          unitsNeeded: int.parse(_units.text.trim()),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SearchDonorsScreen(receiverTokenId: token.id),
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
              const AppHeader(eyebrow: 'Register', title: 'Receiver Details'),
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
                              'Who needs blood',
                              style: AppText.headline(size: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You can register on behalf of a family member or friend.',
                              style: AppText.body(
                                  color: AppColors.inkMuted, size: 13.5),
                            ),
                            const SizedBox(height: 26),
                            AppTextField(
                              label: 'Full name',
                              hint: 'Patient name',
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
                            const SizedBox(height: 24),
                            _CauseSelector(
                              selected: _cause,
                              onChanged: (c) {
                                _dirty = true;
                                setState(() => _cause = c);
                              },
                            ),
                            if (_cause == 'Other') ...[
                              const SizedBox(height: 14),
                              AppTextField(
                                label: 'Describe cause',
                                hint: 'e.g. Open-heart surgery',
                                controller: _causeOther,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ],
                            const SizedBox(height: 24),
                            AppTextField(
                              label: 'Units needed',
                              hint: '1',
                              controller: _units,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              validator: Validators.units,
                            ),
                            const SizedBox(height: 24),
                            BloodGroupSelector(
                              value: _bloodGroup,
                              onChanged: (g) {
                                _dirty = true;
                                setState(() => _bloodGroup = g);
                              },
                              label: 'Required blood group',
                            ),
                            const SizedBox(height: 34),
                            AppButton(
                              label: _saving ? 'Saving' : 'Save & Find donors',
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

class _CauseSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CauseSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAUSE / CONDITION', style: AppText.label()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Causes.options.map((c) {
            final isSelected = c == selected;
            return Material(
              color: isSelected ? AppColors.ink : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.ink
                      : AppColors.hairlineStrong,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => onChanged(c),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    c,
                    style: AppText.body(
                      color: isSelected ? AppColors.onMaroon : AppColors.ink,
                      size: 13,
                    ).copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
