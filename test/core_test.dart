import 'package:flutter_test/flutter_test.dart';
import 'package:souqna/l10n/app_localizations_ar.dart';
import 'package:souqna/l10n/app_localizations_en.dart';
import 'package:souqna/core/validators.dart';
import 'package:souqna/models/chat.dart';
import 'package:souqna/models/listing.dart';

void main() {
  group('search keywords', () {
    test('builds lowercase prefixes for English and Arabic', () {
      final k = Listing.buildKeywords('iPhone 15 سيارة');
      expect(k, containsAll(['ip', 'iphone', '15', 'سي', 'سيارة']));
      expect(k.every((w) => w == w.toLowerCase()), isTrue);
    });

    test('strips punctuation and caps size', () {
      expect(Listing.searchWords('MacBook-Air, M3!'), ['macbook', 'air', 'm3']);
      expect(Listing.buildKeywords(List.filled(50, 'wordwordword').join(' ')).length, lessThanOrEqualTo(80));
    });
  });

  group('validators', () {
    final v = Validators(AppLocalizationsEn());
    test('email', () {
      expect(v.email('a@b.co'), isNull);
      expect(v.email('nope'), isNotNull);
    });
    test('password requires 8+ chars with letters and digits', () {
      expect(v.password('short1'), isNotNull);
      expect(v.password('allletters'), isNotNull);
      expect(v.password('Secure123'), isNull);
    });
    test('phone', () {
      expect(v.phone('+962 79 000 0000'), isNull);
      expect(v.phone('abc'), isNotNull);
      expect(v.phone('', optional: true), isNull);
    });
    test('price', () {
      expect(v.price('99.5'), isNull);
      expect(v.price('-1'), isNotNull);
    });
  });

  test('chat id is deterministic per listing and buyer', () {
    expect(Chat.idFor('L1', 'U1'), 'L1_U1');
  });

  test('arabic plural forms', () {
    final ar = AppLocalizationsAr();
    expect(ar.viewsCount(2), 'مشاهدتان');
    expect(ar.daysAgo(1), 'أمس');
  });
}
