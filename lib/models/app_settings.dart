import 'package:cloud_firestore/cloud_firestore.dart';

/// Global app configuration stored at `settings/app`, editable by admins only.
class AppSettings {
  const AppSettings({
    this.autoApprove = false,
    this.maxImages = 8,
    this.supportPhone = '',
    this.supportEmail = '',
    this.announcementEn = '',
    this.announcementAr = '',
  });

  final bool autoApprove;
  final int maxImages;
  final String supportPhone;
  final String supportEmail;
  final String announcementEn;
  final String announcementAr;

  factory AppSettings.fromMap(Map<String, dynamic>? d) {
    if (d == null) return const AppSettings();
    return AppSettings(
      autoApprove: (d['autoApprove'] ?? false) as bool,
      maxImages: ((d['maxImages'] ?? 8) as num).toInt().clamp(1, 10),
      supportPhone: (d['supportPhone'] ?? '') as String,
      supportEmail: (d['supportEmail'] ?? '') as String,
      announcementEn: (d['announcementEn'] ?? '') as String,
      announcementAr: (d['announcementAr'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'autoApprove': autoApprove,
        'maxImages': maxImages,
        'supportPhone': supportPhone.trim(),
        'supportEmail': supportEmail.trim(),
        'announcementEn': announcementEn.trim(),
        'announcementAr': announcementAr.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
