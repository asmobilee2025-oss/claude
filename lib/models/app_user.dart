import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { active, banned }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    this.city = '',
    this.bio = '',
    this.status = UserStatus.active,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String city;
  final String bio;
  final UserStatus status;
  final DateTime? createdAt;

  bool get isBanned => status == UserStatus.banned;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      email: '',
      phone: '',
      photoUrl: (d['photoUrl'] ?? '') as String,
      city: (d['city'] ?? '') as String,
      bio: (d['bio'] ?? '') as String,
      status: d['status'] == 'banned' ? UserStatus.banned : UserStatus.active,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Public fields a user may edit on their own profile (enforced by security rules).
  /// Email and phone live in `users/{uid}/private/info`, readable only by the
  /// owner and admins, so they can't be scraped from public profiles.
  Map<String, dynamic> toProfileUpdate() => {
        'name': name,
        'photoUrl': photoUrl,
        'city': city,
        'bio': bio,
      };

  AppUser withPrivate(Map<String, dynamic>? d) => AppUser(
        id: id,
        name: name,
        email: (d?['email'] ?? '') as String,
        phone: (d?['phone'] ?? '') as String,
        photoUrl: photoUrl,
        city: city,
        bio: bio,
        status: status,
        createdAt: createdAt,
      );

  AppUser copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? city,
    String? bio,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        city: city ?? this.city,
        bio: bio ?? this.bio,
        status: status,
        createdAt: createdAt,
      );
}
