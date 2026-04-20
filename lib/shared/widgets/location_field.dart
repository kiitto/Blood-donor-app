import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/cities.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text_field.dart';

/// Text + autocomplete + GPS button. On tap-out, hides suggestions.
class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const LocationField({
    super.key,
    required this.controller,
    this.label = 'Location',
    this.hint = 'City, State',
    this.validator,
    this.onChanged,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  List<String> _suggestions = const [];
  bool _fetchingGps = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        setState(() => _suggestions = const []);
      } else {
        _update(widget.controller.text);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _update(String q) {
    setState(() => _suggestions = Cities.search(q));
  }

  Future<void> _useGps() async {
    setState(() => _fetchingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          _snack('Location permission denied');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality?.trim().isNotEmpty == true
            ? p.locality!.trim()
            : (p.subAdministrativeArea ?? '').trim();
        final state = (p.administrativeArea ?? '').trim();
        final text = [city, state].where((s) => s.isNotEmpty).join(', ');
        if (text.isNotEmpty) {
          widget.controller.text = text;
          widget.onChanged?.call(text);
          setState(() => _suggestions = const []);
        } else {
          _snack('Could not resolve address');
        }
      }
    } catch (_) {
      if (mounted) _snack('Location unavailable — type it in');
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: widget.label,
            hint: widget.hint,
            controller: widget.controller,
            focusNode: _focus,
            textCapitalization: TextCapitalization.words,
            validator: widget.validator,
            onChanged: (v) {
              _update(v);
              widget.onChanged?.call(v);
            },
            trailing: _GpsButton(loading: _fetchingGps, onPressed: _useGps),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.hairline),
                  right: BorderSide(color: AppColors.hairline),
                  bottom: BorderSide(color: AppColors.hairline),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _suggestions
                    .map((s) => InkWell(
                          onTap: () {
                            widget.controller.text = s;
                            widget.onChanged?.call(s);
                            _focus.unfocus();
                            setState(() => _suggestions = const []);
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            child: Text(s, style: AppText.body()),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      );
}

class _GpsButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _GpsButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: loading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.4,
                    color: AppColors.maroon,
                  ),
                )
              : const Icon(Icons.my_location_outlined,
                  size: 18, color: AppColors.maroon),
        ),
      );
}
