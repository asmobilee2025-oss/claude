import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';

enum ListingSort { newest, priceLow, priceHigh }

class ListingFilter {
  const ListingFilter({
    this.categoryId,
    this.city,
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.sort = ListingSort.newest,
    this.featuredOnly = false,
  });

  final String? categoryId;
  final String? city;
  final String query;
  final double? minPrice;
  final double? maxPrice;
  final ListingCondition? condition;
  final ListingSort sort;
  final bool featuredOnly;

  bool get hasExtraFilters =>
      city != null || minPrice != null || maxPrice != null || condition != null || sort != ListingSort.newest;

  ListingFilter copyWith({
    String? Function()? categoryId,
    String? Function()? city,
    String? query,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    ListingCondition? Function()? condition,
    ListingSort? sort,
  }) =>
      ListingFilter(
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        city: city != null ? city() : this.city,
        query: query ?? this.query,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        condition: condition != null ? condition() : this.condition,
        sort: sort ?? this.sort,
        featuredOnly: featuredOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is ListingFilter &&
      other.categoryId == categoryId &&
      other.city == city &&
      other.query == query &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.condition == condition &&
      other.sort == sort &&
      other.featuredOnly == featuredOnly;

  @override
  int get hashCode => Object.hash(categoryId, city, query, minPrice, maxPrice, condition, sort, featuredOnly);
}

class ListingPage {
  const ListingPage(this.items, this.lastDoc, this.hasMore);
  final List<Listing> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class ListingRepository {
  ListingRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('listings');

  /// Public browse query. Equality filters + sort run server-side (see
  /// firestore.indexes.json); price range and multi-word search are refined
  /// client-side on each page.
  Future<ListingPage> fetchPage(
    ListingFilter f, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'active');
    if (f.featuredOnly) q = q.where('featured', isEqualTo: true);
    if (f.categoryId != null) q = q.where('categoryId', isEqualTo: f.categoryId);
    if (f.city != null) q = q.where('city', isEqualTo: f.city);
    if (f.condition != null) {
      q = q.where('condition', isEqualTo: f.condition == ListingCondition.newItem ? 'new' : 'used');
    }
    final words = Listing.searchWords(f.query);
    if (words.isNotEmpty) q = q.where('searchKeywords', arrayContains: words.first);
    switch (f.sort) {
      case ListingSort.newest:
        q = q.orderBy('createdAt', descending: true);
      case ListingSort.priceLow:
        q = q.orderBy('price');
      case ListingSort.priceHigh:
        q = q.orderBy('price', descending: true);
    }
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.limit(limit).get();
    var items = snap.docs.map(Listing.fromDoc).toList();
    items = items.where((l) {
      if (f.minPrice != null && l.price < f.minPrice!) return false;
      if (f.maxPrice != null && l.price > f.maxPrice!) return false;
      if (words.length > 1) {
        final kws = Listing.buildKeywords(l.title).toSet();
        if (!words.every(kws.contains)) return false;
      }
      return true;
    }).toList();
    return ListingPage(items, snap.docs.isEmpty ? null : snap.docs.last, snap.docs.length == limit);
  }

  Stream<Listing?> watch(String id) =>
      _col.doc(id).snapshots().map((d) => d.exists ? Listing.fromDoc(d) : null);

  Stream<List<Listing>> watchByOwner(String uid) => _col
      .where('ownerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList());

  Stream<List<Listing>> watchActiveByOwner(String uid) => _col
      .where('ownerId', isEqualTo: uid)
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList());

  Stream<List<Listing>> watchFeatured() => _col
      .where('status', isEqualTo: 'active')
      .where('featured', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList());

  Stream<List<Listing>> watchLatest({int limit = 20}) => _col
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Listing.fromDoc).toList());

  Future<List<Listing>> byIds(List<String> ids) async {
    final out = <Listing>[];
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _col.where(FieldPath.documentId, whereIn: chunk).where('status', isEqualTo: 'active').get();
      out.addAll(snap.docs.map(Listing.fromDoc));
    }
    return out;
  }

  String newId() => _col.doc().id;

  Future<void> create(String id, Listing l, {required bool autoApprove}) => _col.doc(id).set({
        ...l.toContentMap(),
        'ownerId': l.ownerId,
        'status': autoApprove ? 'active' : 'pending',
        'rejectionReason': '',
        'featured': false,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Any content edit sends the ad back to review unless auto-approve is on.
  Future<void> update(Listing l, {required bool autoApprove}) => _col.doc(l.id).update({
        ...l.toContentMap(),
        'status': autoApprove ? 'active' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> markSold(String id) =>
      _col.doc(id).update({'status': 'sold', 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> incrementViews(String id) => _col.doc(id).update({'views': FieldValue.increment(1)});

  // ---- Admin moderation (permitted only for admins by security rules) ----

  Stream<List<Listing>> watchByStatus(String? status, {int limit = 100}) {
    Query<Map<String, dynamic>> q = _col;
    if (status != null) q = q.where('status', isEqualTo: status);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Listing.fromDoc).toList());
  }

  Future<void> moderate(String id, ListingStatus status, {String reason = ''}) => _col.doc(id).update({
        'status': status.name,
        'rejectionReason': status == ListingStatus.rejected ? reason : '',
        'moderatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setFeatured(String id, bool featured) => _col.doc(id).update({'featured': featured});
}
