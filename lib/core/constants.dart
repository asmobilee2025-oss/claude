import 'package:flutter/widgets.dart';

class AppConstants {
  static const appName = 'Souqna';
  static const currency = 'JOD';
  static const maxImageBytes = 5 * 1024 * 1024; // must match storage.rules
  static const pageSize = 20;
  static const titleMax = 100;
  static const descriptionMax = 4000;
  static const messageMax = 1000;
}

class City {
  const City(this.id, this.en, this.ar);
  final String id;
  final String en;
  final String ar;
  String name(Locale l) => l.languageCode == 'ar' ? ar : en;
}

const List<City> cities = [
  City('amman', 'Amman', 'عمّان'),
  City('zarqa', 'Zarqa', 'الزرقاء'),
  City('irbid', 'Irbid', 'إربد'),
  City('aqaba', 'Aqaba', 'العقبة'),
  City('salt', 'Salt', 'السلط'),
  City('madaba', 'Madaba', 'مادبا'),
  City('jerash', 'Jerash', 'جرش'),
  City('ajloun', 'Ajloun', 'عجلون'),
  City('mafraq', 'Mafraq', 'المفرق'),
  City('karak', 'Karak', 'الكرك'),
  City('tafilah', 'Tafilah', 'الطفيلة'),
  City('maan', "Ma'an", 'معان'),
];

String cityName(String id, Locale l) =>
    cities.firstWhere((c) => c.id == id, orElse: () => City(id, id, id)).name(l);
