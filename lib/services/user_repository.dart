import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<AppUser?> watch(String uid) =>
      _users.doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<AppUser?> get(String uid) async {
    final d = await _users.doc(uid).get();
    return d.exists ? AppUser.fromDoc(d) : null;
  }

  DocumentReference<Map<String, dynamic>> _private(String uid) => _users.doc(uid).collection('private').doc('info');

  Stream<Map<String, dynamic>?> watchPrivate(String uid) => _private(uid).snapshots().map((d) => d.data());

  Future<Map<String, dynamic>?> getPrivate(String uid) async => (await _private(uid).get()).data();

  Future<void> updateProfile(AppUser u) {
    final batch = _db.batch()
      ..update(_users.doc(u.id), u.toProfileUpdate())
      ..set(_private(u.id), {'phone': u.phone}, SetOptions(merge: true));
    return batch.commit();
  }

  // ---- Favorites ----
  CollectionReference<Map<String, dynamic>> _favs(String uid) => _users.doc(uid).collection('favorites');

  Stream<Set<String>> watchFavoriteIds(String uid) =>
      _favs(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> setFavorite(String uid, String listingId, bool fav) => fav
      ? _favs(uid).doc(listingId).set({'createdAt': FieldValue.serverTimestamp()})
      : _favs(uid).doc(listingId).delete();

  // ---- Admin ----
  Stream<bool> watchIsAdmin(String uid) => _db.collection('admins').doc(uid).snapshots().map((d) => d.exists);

  Stream<List<AppUser>> watchAll({int limit = 200}) => _users
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Stream<Set<String>> watchAdminIds() =>
      _db.collection('admins').snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> setBanned(String uid, bool banned) => _users.doc(uid).update({
        'status': banned ? 'banned' : 'active',
        'statusChangedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setAdmin(String uid, bool admin, String grantedBy) => admin
      ? _db.collection('admins').doc(uid).set({'grantedBy': grantedBy, 'createdAt': FieldValue.serverTimestamp()})
      : _db.collection('admins').doc(uid).delete();
}
