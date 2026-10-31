import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.icon = 'category',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String icon;
  final int order;
  final bool active;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  IconData get iconData => categoryIcons[icon] ?? Icons.category_outlined;

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Category(
      id: doc.id,
      nameEn: (d['nameEn'] ?? '') as String,
      nameAr: (d['nameAr'] ?? '') as String,
      icon: (d['icon'] ?? 'category') as String,
      order: ((d['order'] ?? 0) as num).toInt(),
      active: (d['active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'nameEn': nameEn.trim(),
        'nameAr': nameAr.trim(),
        'icon': icon,
        'order': order,
        'active': active,
      };
}

/// Icon keys stored in Firestore mapped to Material icons.
const Map<String, IconData> categoryIcons = {
  'category': Icons.category_outlined,
  'car': Icons.directions_car_outlined,
  'home': Icons.home_work_outlined,
  'phone': Icons.smartphone_outlined,
  'laptop': Icons.laptop_mac_outlined,
  'electronics': Icons.devices_other_outlined,
  'furniture': Icons.chair_outlined,
  'fashion': Icons.checkroom_outlined,
  'jobs': Icons.work_outline,
  'services': Icons.handyman_outlined,
  'pets': Icons.pets_outlined,
  'kids': Icons.child_friendly_outlined,
  'sports': Icons.sports_soccer_outlined,
  'games': Icons.sports_esports_outlined,
  'books': Icons.menu_book_outlined,
  'watch': Icons.watch_outlined,
  'camera': Icons.photo_camera_outlined,
  'tools': Icons.build_outlined,
};

/// Starter set an admin can load with one tap from the admin dashboard.
const List<Category> defaultCategories = [
  Category(id: 'vehicles', nameEn: 'Vehicles', nameAr: 'سيارات ومركبات', icon: 'car', order: 1),
  Category(id: 'real-estate', nameEn: 'Real Estate', nameAr: 'عقارات', icon: 'home', order: 2),
  Category(id: 'mobiles', nameEn: 'Mobiles & Tablets', nameAr: 'موبايلات وتابلت', icon: 'phone', order: 3),
  Category(id: 'computers', nameEn: 'Computers & Laptops', nameAr: 'كمبيوتر ولابتوب', icon: 'laptop', order: 4),
  Category(id: 'electronics', nameEn: 'Electronics', nameAr: 'إلكترونيات', icon: 'electronics', order: 5),
  Category(id: 'furniture', nameEn: 'Home & Furniture', nameAr: 'أثاث ومنزل', icon: 'furniture', order: 6),
  Category(id: 'fashion', nameEn: 'Fashion', nameAr: 'أزياء وموضة', icon: 'fashion', order: 7),
  Category(id: 'jobs', nameEn: 'Jobs', nameAr: 'وظائف', icon: 'jobs', order: 8),
  Category(id: 'services', nameEn: 'Services', nameAr: 'خدمات', icon: 'services', order: 9),
  Category(id: 'pets', nameEn: 'Pets', nameAr: 'حيوانات أليفة', icon: 'pets', order: 10),
  Category(id: 'kids', nameEn: 'Kids & Babies', nameAr: 'أطفال ومستلزمات', icon: 'kids', order: 11),
  Category(id: 'sports', nameEn: 'Sports & Hobbies', nameAr: 'رياضة وهوايات', icon: 'sports', order: 12),
];
