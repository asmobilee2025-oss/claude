import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/report.dart';

/// Categories, global settings, reports and dashboard statistics.
class CatalogRepository {
  CatalogRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _cats => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _reports => _db.collection('reports');
  DocumentReference<Map<String, dynamic>> get _settings => _db.collection('settings').doc('app');

  Stream<List<Category>> watchCategories() => _cats.orderBy('order').snapshots().map(
        (s) => s.docs.map(Category.fromDoc).toList(),
      );

  Future<void> saveCategory(Category c) => _cats.doc(c.id).set(c.toMap());
  Future<void> deleteCategory(String id) => _cats.doc(id).delete();

  Future<void> seedDefaultCategories() async {
    final batch = _db.batch();
    for (final c in defaultCategories) {
      batch.set(_cats.doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  Stream<AppSettings> watchSettings() => _settings.snapshots().map((d) => AppSettings.fromMap(d.data()));
  Future<void> saveSettings(AppSettings s) => _settings.set(s.toMap());

  Future<void> report({
    required String reporterId,
    required String listingId,
    required String listingTitle,
    required String reason,
    required String details,
  }) =>
      _reports.add({
        'reporterId': reporterId,
        'listingId': listingId,
        'listingTitle': listingTitle,
        'reason': reason,
        'details': details.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Report>> watchReports({String? status}) {
    Query<Map<String, dynamic>> q = _reports;
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.orderBy('createdAt', descending: true).limit(200).snapshots().map(
          (s) => s.docs.map(Report.fromDoc).toList(),
        );
  }

  Future<void> setReportStatus(String id, ReportStatus s) =>
      _reports.doc(id).update({'status': s.name, 'handledAt': FieldValue.serverTimestamp()});

  Future<DashboardStats> stats() async {
    Future<int> count(Query<Map<String, dynamic>> q) async => (await q.count().get()).count ?? 0;
    final listings = _db.collection('listings');
    final weekAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    final r = await Future.wait([
      count(_db.collection('users')),
      count(_db.collection('users').where('createdAt', isGreaterThanOrEqualTo: weekAgo)),
      count(listings),
      count(listings.where('status', isEqualTo: 'active')),
      count(listings.where('status', isEqualTo: 'pending')),
      count(listings.where('status', isEqualTo: 'sold')),
      count(listings.where('status', isEqualTo: 'rejected')),
      count(_reports.where('status', isEqualTo: 'open')),
      count(_db.collection('users').where('status', isEqualTo: 'banned')),
      count(listings.where('createdAt', isGreaterThanOrEqualTo: weekAgo)),
    ]);
    return DashboardStats(
      users: r[0],
      newUsersWeek: r[1],
      listings: r[2],
      active: r[3],
      pending: r[4],
      sold: r[5],
      rejected: r[6],
      openReports: r[7],
      banned: r[8],
      newListingsWeek: r[9],
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.users,
    required this.newUsersWeek,
    required this.listings,
    required this.active,
    required this.pending,
    required this.sold,
    required this.rejected,
    required this.openReports,
    required this.banned,
    required this.newListingsWeek,
  });

  final int users, newUsersWeek, listings, active, pending, sold, rejected, openReports, banned, newListingsWeek;
}
