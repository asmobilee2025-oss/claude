import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingStatus { pending, active, rejected, sold }

enum ListingCondition { newItem, used }

ListingStatus listingStatusFrom(String? v) => ListingStatus.values.firstWhere(
      (s) => s.name == v,
      orElse: () => ListingStatus.pending,
    );

class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.city,
    this.currency = 'JOD',
    this.negotiable = false,
    this.condition = ListingCondition.used,
    this.images = const [],
    this.contactPhone = '',
    this.showPhone = true,
    this.status = ListingStatus.pending,
    this.rejectionReason = '',
    this.featured = false,
    this.views = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final double price;
  final String currency;
  final bool negotiable;
  final String categoryId;
  final String city;
  final ListingCondition condition;
  final List<String> images;
  final String contactPhone;
  final bool showPhone;
  final ListingStatus status;
  final String rejectionReason;
  final bool featured;
  final int views;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get coverImage => images.isEmpty ? null : images.first;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Listing(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '') as String,
      ownerName: (d['ownerName'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      price: ((d['price'] ?? 0) as num).toDouble(),
      currency: (d['currency'] ?? 'JOD') as String,
      negotiable: (d['negotiable'] ?? false) as bool,
      categoryId: (d['categoryId'] ?? '') as String,
      city: (d['city'] ?? '') as String,
      condition: d['condition'] == 'new' ? ListingCondition.newItem : ListingCondition.used,
      images: List<String>.from((d['images'] ?? const []) as List),
      contactPhone: (d['contactPhone'] ?? '') as String,
      showPhone: (d['showPhone'] ?? true) as bool,
      status: listingStatusFrom(d['status'] as String?),
      rejectionReason: (d['rejectionReason'] ?? '') as String,
      featured: (d['featured'] ?? false) as bool,
      views: ((d['views'] ?? 0) as num).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Content fields the owner controls. Moderation fields (featured, views,
  /// rejectionReason) are never written by the client on behalf of the owner.
  Map<String, dynamic> toContentMap() => {
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'currency': currency,
        'negotiable': negotiable,
        'categoryId': categoryId,
        'city': city,
        'condition': condition == ListingCondition.newItem ? 'new' : 'used',
        'images': images,
        // Phone is only stored when the owner chose to show it publicly.
        'contactPhone': showPhone ? contactPhone.trim() : '',
        'showPhone': showPhone,
        'ownerName': ownerName,
        'searchKeywords': buildKeywords(title),
      };

  /// Lowercased word prefixes used for `array-contains` search.
  static List<String> buildKeywords(String text) {
    final out = <String>{};
    for (final w in searchWords(text)) {
      for (var i = 2; i <= w.length && i <= 15; i++) {
        out.add(w.substring(0, i));
      }
      if (w.length == 1) out.add(w);
    }
    return out.take(80).toList();
  }

  /// Normalized search words (max 15 chars each, matching [buildKeywords]).
  static List<String> searchWords(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.length > 15 ? w.substring(0, 15) : w)
      .toList();

  Listing copyWith({
    String? title,
    String? description,
    double? price,
    bool? negotiable,
    String? categoryId,
    String? city,
    ListingCondition? condition,
    List<String>? images,
    String? contactPhone,
    bool? showPhone,
    String? ownerName,
  }) =>
      Listing(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName ?? this.ownerName,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        currency: currency,
        negotiable: negotiable ?? this.negotiable,
        categoryId: categoryId ?? this.categoryId,
        city: city ?? this.city,
        condition: condition ?? this.condition,
        images: images ?? this.images,
        contactPhone: contactPhone ?? this.contactPhone,
        showPhone: showPhone ?? this.showPhone,
        status: status,
        rejectionReason: rejectionReason,
        featured: featured,
        views: views,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
