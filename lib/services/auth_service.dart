import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth that also maintains the `users/{uid}` profile.
class AuthService {
  AuthService(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;
  Stream<User?> userChanges() => _auth.userChanges();

  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await ensureProfile(cred.user!);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _createProfile(
      user.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.replaceAll(RegExp(r'[\s-]'), ''),
    );
    await user.sendEmailVerification();
  }

  /// Creates the profile document if it is missing (e.g. account made in console).
  Future<void> ensureProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await _createProfile(
      user.uid,
      name: user.displayName ?? (user.email ?? '').split('@').first,
      email: (user.email ?? '').toLowerCase(),
      phone: '',
    );
  }

  Future<void> _createProfile(String uid, {required String name, required String email, required String phone}) {
    final ref = _db.collection('users').doc(uid);
    final batch = _db.batch()
      ..set(ref, {
        'name': name,
        'photoUrl': '',
        'city': '',
        'bio': '',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(ref.collection('private').doc('info'), {'email': email, 'phone': phone});
    return batch.commit();
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async => _auth.currentUser?.sendEmailVerification();

  /// Reloads the user and refreshes the ID token so `email_verified` reaches security rules.
  Future<bool> refreshVerification() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    await u.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> changePassword(String current, String next) async {
    final u = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(email: u.email!, password: current);
    await u.reauthenticateWithCredential(cred);
    await u.updatePassword(next);
  }

  Future<void> signOut() => _auth.signOut();
}

/// Maps Firebase error codes to localization keys used by the UI.
String authErrorKey(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'invalidEmail';
      case 'user-disabled':
        return 'accountDisabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'wrongCredentials';
      case 'email-already-in-use':
        return 'emailInUse';
      case 'weak-password':
        return 'passwordWeak';
      case 'too-many-requests':
        return 'tooManyRequests';
      case 'network-request-failed':
        return 'networkError';
    }
  }
  return 'genericError';
}
