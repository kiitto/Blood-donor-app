import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/location_field.dart';
import '../../state/auth_provider.dart';

Future<void> showLocationSheet(BuildContext context, {required String initial}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
    ),
    builder: (_) => _LocationSheet(initial: initial),
  );
}

class _LocationSheet extends StatefulWidget {
  final String initial;
  const _LocationSheet({required this.initial});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().editProfile(location: _controller.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
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
              Text('Change location', style: AppText.headline(size: 22)),
              const SizedBox(height: 4),
              Text(
                'We use this to help receivers find nearby donors.',
                style: AppText.body(color: AppColors.inkMuted, size: 13),
              ),
              const SizedBox(height: 20),
              LocationField(
                controller: _controller,
                validator: (v) => Validators.required(v, label: 'Location'),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _saving ? 'Saving' : 'Save location',
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
