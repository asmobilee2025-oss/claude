import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

/// Bottom navigation on phones, navigation rail on tablets / desktop / web.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  // Visual destinations: 0 home, 1 browse, 2 post (action), 3 chats, 4 account.
  int get _selected => shell.currentIndex >= 2 ? shell.currentIndex + 1 : shell.currentIndex;

  void _onTap(BuildContext context, int i) {
    if (i == 2) {
      context.push('/post');
      return;
    }
    final branch = i > 2 ? i - 1 : i;
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final unread = ref.watch(unreadCountProvider);
    final profile = ref.watch(currentProfileProvider).value;

    Widget chatIcon(bool selected) => Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: Icon(selected ? Icons.chat_bubble : Icons.chat_bubble_outline),
        );

    Widget body = shell;
    if (profile?.isBanned ?? false) {
      body = Column(children: [
        MaterialBanner(
          backgroundColor: context.colors.errorContainer,
          content: Text(t.accountBanned, style: TextStyle(color: context.colors.onErrorContainer)),
          actions: [TextButton(onPressed: () => ref.read(authServiceProvider).signOut(), child: Text(t.logout))],
        ),
        Expanded(child: shell),
      ]);
    }

    if (context.isCompact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selected,
          onDestinationSelected: (i) => _onTap(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.home),
            NavigationDestination(icon: const Icon(Icons.search), label: t.browse),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.add, color: context.colors.onPrimary),
              ),
              label: t.postAd,
            ),
            NavigationDestination(icon: chatIcon(false), selectedIcon: chatIcon(true), label: t.chats),
            NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: t.account),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(children: [
        NavigationRail(
          extended: context.isExpanded,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          labelType: context.isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Icon(Icons.storefront, color: context.colors.primary, size: 32),
              const SizedBox(height: 16),
              context.isExpanded
                  ? FilledButton.icon(onPressed: () => context.push('/post'), icon: const Icon(Icons.add), label: Text(t.postAd))
                  : FloatingActionButton.small(
                      heroTag: 'rail-post',
                      tooltip: t.postAd,
                      onPressed: () => context.push('/post'),
                      child: const Icon(Icons.add),
                    ),
            ]),
          ),
          destinations: [
            NavigationRailDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: Text(t.home)),
            NavigationRailDestination(icon: const Icon(Icons.search), label: Text(t.browse)),
            NavigationRailDestination(icon: chatIcon(false), selectedIcon: chatIcon(true), label: Text(t.chats)),
            NavigationRailDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: Text(t.account)),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ]),
    );
  }
}
