import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/admin_categories_screen.dart';
import 'features/admin/admin_listings_screen.dart';
import 'features/admin/admin_overview_screen.dart';
import 'features/admin/admin_reports_screen.dart';
import 'features/admin/admin_settings_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/admin_users_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/chats_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/main_shell.dart';
import 'features/listings/browse_screen.dart';
import 'features/listings/listing_detail_screen.dart';
import 'features/listings/post_listing_screen.dart';
import 'features/profile/account_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/favorites_screen.dart';
import 'features/profile/my_listings_screen.dart';
import 'features/profile/seller_screen.dart';
import 'features/profile/settings_screen.dart';
import 'providers/providers.dart';

const _protected = ['/post', '/edit', '/chat', '/my-listings', '/favorites', '/profile', '/admin'];

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(isAdminProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading && !auth.hasValue) return null;
      final loggedIn = auth.value != null;
      final path = state.uri.path;

      final needsAuth = _protected.any((p) => path == p || path.startsWith('$p/') || path.startsWith(p));
      if (!loggedIn && needsAuth) {
        return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
      }
      if (loggedIn && (path == '/login' || path == '/register' || path == '/forgot-password')) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.startsWith('/') && !from.startsWith('//')) ? from : '/';
      }
      if (path.startsWith('/admin')) {
        // Only redirect on a settled answer; while auth/admin state is still
        // resolving (e.g. page refresh), AdminShell shows a loader instead.
        final admin = ref.read(isAdminProvider);
        if (!admin.isLoading && admin.hasValue && admin.value == false) return '/';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/browse',
              builder: (_, s) => BrowseScreen(
                key: ValueKey(s.uri.toString()),
                categoryId: s.uri.queryParameters['category'],
                query: s.uri.queryParameters['q'] ?? '',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/chats', builder: (_, _) => const ChatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())]),
        ],
      ),
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/register', builder: (_, s) => RegisterScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/listing/:id', builder: (_, s) => ListingDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/seller/:id', builder: (_, s) => SellerScreen(uid: s.pathParameters['id']!)),
      GoRoute(path: '/post', builder: (_, _) => const PostListingScreen()),
      GoRoute(path: '/edit/:id', builder: (_, s) => PostListingScreen(editId: s.pathParameters['id'])),
      GoRoute(path: '/chat/:id', builder: (_, s) => ChatScreen(chatId: s.pathParameters['id']!)),
      GoRoute(path: '/my-listings', builder: (_, _) => const MyListingsScreen()),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, _) => const AdminOverviewScreen()),
          GoRoute(
            path: '/admin/listings',
            builder: (_, s) => AdminListingsScreen(initialStatus: s.uri.queryParameters['status']),
          ),
          GoRoute(path: '/admin/users', builder: (_, _) => const AdminUsersScreen()),
          GoRoute(path: '/admin/categories', builder: (_, _) => const AdminCategoriesScreen()),
          GoRoute(path: '/admin/reports', builder: (_, _) => const AdminReportsScreen()),
          GoRoute(path: '/admin/settings', builder: (_, _) => const AdminSettingsScreen()),
        ],
      ),
    ],
  );
});
