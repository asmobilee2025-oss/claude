import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// The user dashboard: profile summary, ad statistics and account menu.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.account)),
        body: ListView(children: [
          EmptyState(
            icon: Icons.person_outline,
            title: t.guestTitle,
            subtitle: t.guestSubtitle,
            action: Wrap(spacing: 12, children: [
              FilledButton(onPressed: () => context.push('/login'), child: Text(t.login)),
              OutlinedButton(onPressed: () => context.push('/register'), child: Text(t.createAccount)),
            ]),
          ),
          MaxWidth(maxWidth: 700, child: ListTile(leading: const Icon(Icons.settings_outlined), title: Text(t.settings), onTap: () => context.push('/settings'))),
        ]),
      );
    }

    final profile = ref.watch(currentProfileProvider).value;
    final listings = ref.watch(myListingsProvider).value ?? const <Listing>[];
    final favs = ref.watch(favoriteIdsProvider).value?.length ?? 0;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final unread = ref.watch(unreadCountProvider);
    final active = listings.where((l) => l.status == ListingStatus.active).length;
    final pending = listings.where((l) => l.status == ListingStatus.pending).length;
    final views = listings.fold<int>(0, (s, l) => s + l.views);

    Widget stat(String label, int value, IconData icon, VoidCallback onTap) => Expanded(
          child: Card(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(children: [
                  Icon(icon, color: context.colors.primary),
                  const SizedBox(height: 6),
                  Text('$value', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.outline), textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(t.myDashboard)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        MaxWidth(
          maxWidth: 800,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Avatar(name: profile?.name ?? '', url: profile?.photoUrl ?? '', radius: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(profile?.name ?? '', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(user.email ?? '', style: TextStyle(color: context.colors.outline)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (user.emailVerified)
                          StatusChip(label: t.verified, color: Colors.green.shade700)
                        else
                          StatusChip(label: t.notVerified, color: Colors.orange.shade800),
                        if (isAdmin) StatusChip(label: t.admin, color: context.colors.primary),
                      ]),
                    ]),
                  ),
                  IconButton(tooltip: t.editProfile, onPressed: () => context.push('/profile/edit'), icon: const Icon(Icons.edit_outlined)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              stat(t.activeAds, active, Icons.storefront_outlined, () => context.push('/my-listings')),
              const SizedBox(width: 8),
              stat(t.pendingAds, pending, Icons.hourglass_top, () => context.push('/my-listings')),
              const SizedBox(width: 8),
              stat(t.totalViews, views, Icons.visibility_outlined, () => context.push('/my-listings')),
              if (!context.isCompact) ...[
                const SizedBox(width: 8),
                stat(t.favorites, favs, Icons.favorite_border, () => context.push('/favorites')),
              ],
            ]),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: Text(t.myAds),
                  trailing: Text('${listings.length}'),
                  onTap: () => context.push('/my-listings'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(t.favorites),
                  trailing: Text('$favs'),
                  onTap: () => context.push('/favorites'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(t.chats),
                  trailing: unread > 0 ? Badge(label: Text('$unread')) : null,
                  onTap: () => context.go('/chats'),
                ),
                const Divider(),
                ListTile(leading: const Icon(Icons.person_outline), title: Text(t.editProfile), onTap: () => context.push('/profile/edit')),
                const Divider(),
                ListTile(leading: const Icon(Icons.settings_outlined), title: Text(t.settings), onTap: () => context.push('/settings')),
                if (isAdmin) ...[
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined, color: context.colors.primary),
                    title: Text(t.adminDashboard, style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700)),
                    onTap: () => context.push('/admin'),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: context.colors.error),
              onPressed: () async {
                if (await confirmDialog(context, title: t.logout, message: t.logoutConfirm)) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/');
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(t.logout),
            ),
          ]),
        ),
      ]),
    );
  }
}
