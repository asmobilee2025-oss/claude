import '../l10n/app_localizations.dart';

/// Form validators. The same limits are enforced server-side in firestore.rules.
class Validators {
  Validators(this.t);
  final AppLocalizations t;

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phone = RegExp(r'^\+?[0-9]{7,15}$');

  String? required(String? v) => (v == null || v.trim().isEmpty) ? t.fieldRequired : null;

  String? email(String? v) {
    if (v == null || v.trim().isEmpty) return t.fieldRequired;
    return _email.hasMatch(v.trim()) ? null : t.invalidEmail;
  }

  String? password(String? v) {
    if (v == null || v.isEmpty) return t.fieldRequired;
    if (v.length < 8) return t.passwordTooShort;
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) return t.passwordWeak;
    return null;
  }

  String? phone(String? v, {bool optional = false}) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (s.isEmpty) return optional ? null : t.fieldRequired;
    return _phone.hasMatch(s) ? null : t.invalidPhone;
  }

  String? length(String? v, {int min = 1, required int max}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return t.fieldRequired;
    if (s.length < min) return t.tooShort(min);
    if (s.length > max) return t.tooLong(max);
    return null;
  }

  String? price(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return t.fieldRequired;
    final p = double.tryParse(s);
    if (p == null || p < 0 || p > 100000000) return t.invalidPrice;
    return null;
  }
}
