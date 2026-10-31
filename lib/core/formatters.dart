import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

String formatPrice(double price, String currency, Locale locale) {
  final f = NumberFormat.decimalPatternDigits(locale: locale.languageCode, decimalDigits: price % 1 == 0 ? 0 : 2);
  final cur = currency == 'JOD' && locale.languageCode == 'ar' ? 'د.أ' : currency;
  return '${f.format(price)} $cur';
}

String timeAgo(DateTime? date, AppLocalizations t) {
  if (date == null) return t.justNow;
  final d = DateTime.now().difference(date);
  if (d.inMinutes < 1) return t.justNow;
  if (d.inHours < 1) return t.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return t.hoursAgo(d.inHours);
  if (d.inDays < 30) return t.daysAgo(d.inDays);
  return DateFormat.yMMMd(t.localeName).format(date);
}

String formatDate(DateTime? date, Locale locale) =>
    date == null ? '-' : DateFormat.yMMMd(locale.languageCode).format(date);

String formatTime(DateTime? date, Locale locale) =>
    date == null ? '' : DateFormat.jm(locale.languageCode).format(date);
