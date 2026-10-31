import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/listing.dart';
import '../services/auth_service.dart';
import '../services/catalog_repository.dart';
import '../services/chat_repository.dart';
import '../services/listing_repository.dart';
import '../services/storage_service.dart';
import '../services/user_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('override in main'));

final firestoreProvider = Provider((_) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider((_) => FirebaseAuth.instance);
final storageProvider = Provider((_) => FirebaseStorage.instance);

final authServiceProvider = Provider((ref) => AuthService(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));
final listingRepoProvider = Provider((ref) => ListingRepository(ref.watch(firestoreProvider)));
final userRepoProvider = Provider((ref) => UserRepository(ref.watch(firestoreProvider)));
final catalogRepoProvider = Provider((ref) => CatalogRepository(ref.watch(firestoreProvider)));
final chatRepoProvider = Provider((ref) => ChatRepository(ref.watch(firestoreProvider)));
final storageServiceProvider = Provider((ref) => StorageService(ref.watch(storageProvider)));

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).userChanges());

final currentUidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final _myPrivateProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepoProvider).watchPrivate(uid);
});

/// The signed-in user's profile merged with their private contact info.
final currentProfileProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final pub = ref.watch(_publicProfileProvider);
  final priv = ref.watch(_myPrivateProvider);
  if (pub.hasValue && pub.value != null && !priv.hasValue && !priv.hasError) return const AsyncLoading();
  return pub.whenData((u) => u?.withPrivate(priv.value));
});

final _publicProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepoProvider).watch(uid);
});

final isAdminProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(userRepoProvider).watchIsAdmin(uid);
});

final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(<String>{});
  return ref.watch(userRepoProvider).watchFavoriteIds(uid);
});

final myChatsProvider = StreamProvider<List<Chat>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepoProvider).watchMyChats(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  final chats = ref.watch(myChatsProvider).value ?? const [];
  if (uid == null) return 0;
  return chats.fold(0, (total, c) => total + c.unreadFor(uid));
});

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(catalogRepoProvider).watchCategories());

final activeCategoriesProvider = Provider<List<Category>>(
  (ref) => (ref.watch(categoriesProvider).value ?? const []).where((c) => c.active).toList(),
);

final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(catalogRepoProvider).watchSettings());

final listingProvider = StreamProvider.family<Listing?, String>((ref, id) => ref.watch(listingRepoProvider).watch(id));

final featuredListingsProvider = StreamProvider<List<Listing>>((ref) => ref.watch(listingRepoProvider).watchFeatured());

final latestListingsProvider = StreamProvider<List<Listing>>((ref) => ref.watch(listingRepoProvider).watchLatest());

final myListingsProvider = StreamProvider<List<Listing>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(listingRepoProvider).watchByOwner(uid);
});

final userProfileProvider = StreamProvider.family<AppUser?, String>((ref, uid) => ref.watch(userRepoProvider).watch(uid));

final sellerListingsProvider =
    StreamProvider.family<List<Listing>, String>((ref, uid) => ref.watch(listingRepoProvider).watchActiveByOwner(uid));

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

class LocaleController extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    if (saved != null) return Locale(saved);
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(device == 'en' ? 'en' : 'ar');
  }

  void set(Locale l) {
    state = l;
    ref.read(sharedPrefsProvider).setString(_key, l.languageCode);
  }

  void toggle() => set(Locale(state.languageCode == 'ar' ? 'en' : 'ar'));
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  void set(ThemeMode m) {
    state = m;
    ref.read(sharedPrefsProvider).setString(_key, m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
