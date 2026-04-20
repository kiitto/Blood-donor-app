class Validators {
  Validators._();

  static final _emailRe = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');
  static final _phoneRe = RegExp(r'^[6-9]\d{9}$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? required(String? v, {String label = 'This field'}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '$label is required';
    return null;
  }

  static String? name(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Name is required';
    if (s.length < 2) return 'Too short';
    if (!RegExp(r"^[A-Za-z .'\-]+$").hasMatch(s)) return 'Letters only';
    return null;
  }

  /// Indian 10-digit mobile. Input is expected without the +91 prefix.
  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\s+'), '').trim();
    if (s.isEmpty) return 'Phone is required';
    if (!_phoneRe.hasMatch(s)) return 'Enter a 10-digit mobile number';
    return null;
  }

  static String? units(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Units are required';
    final n = int.tryParse(s);
    if (n == null || n <= 0) return 'Enter a positive number';
    if (n > 20) return 'Unreasonably high';
    return null;
  }
}
