import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../models/app_user.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

final _usersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) => ref.watch(userRepoProvider).watchAll(limit: 500));
final _adminIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) => ref.watch(userRepoProvider).watchAdminIds());

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _q = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final admins = ref.watch(_adminIdsProvider).value ?? const <String>{};
    final me = ref.watch(currentUidProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          decoration: InputDecoration(hintText: t.searchUsers, prefixIcon: const Icon(Icons.search)),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final f in [('all', t.all), ('active', t.statusActive), ('banned', t.banned), ('admins', t.admins)])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(label: Text(f.$2), selected: _filter == f.$1, onSelected: (_) => setState(() => _filter = f.$1)),
            ),
        ]),
      ),
      Expanded(
        child: AsyncBody(
          value: ref.watch(_usersProvider),
          data: (all) {
            final items = all.where((u) {
              if (_filter == 'active' && u.isBanned) return false;
              if (_filter == 'banned' && !u.isBanned) return false;
              if (_filter == 'admins' && !admins.contains(u.id)) return false;
              return _q.isEmpty || u.name.toLowerCase().contains(_q) || u.id == _q;
            }).toList();
            if (items.isEmpty) return EmptyState(icon: Icons.person_search_outlined, title: t.noResults);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u = items[i];
                final isAdmin = admins.contains(u.id);
                return Card(
                  child: ListTile(
                    onTap: () => showDialog(context: context, builder: (_) => _UserDetails(user: u)),
                    leading: Avatar(name: u.name, url: u.photoUrl),
                    title: Row(children: [
                      Flexible(child: Text(u.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (isAdmin) ...[const SizedBox(width: 6), StatusChip(label: t.admin, color: context.colors.primary)],
                      if (u.isBanned) ...[const SizedBox(width: 6), StatusChip(label: t.banned, color: context.colors.error)],
                    ]),
                    subtitle: Text(t.memberSince(formatDate(u.createdAt, context.locale))),
                    trailing: u.id == me
                        ? Text(t.you)
                        : PopupMenuButton<String>(
                            onSelected: (v) => _action(context, u, v, me!),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'ban', child: Text(u.isBanned ? t.unbanUser : t.banUser)),
                              PopupMenuItem(value: 'admin', child: Text(isAdmin ? t.removeAdmin : t.makeAdmin)),
                              PopupMenuItem(value: 'ads', child: Text(t.viewAds)),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _action(BuildContext context, AppUser u, String action, String me) async {
    final t = context.t;
    final repo = ref.read(userRepoProvider);
    final admins = ref.read(_adminIdsProvider).value ?? const <String>{};
    try {
      switch (action) {
        case 'ban':
          final ban = !u.isBanned;
          if (!await confirmDialog(context, title: ban ? t.banUser : t.unbanUser, message: ban ? t.banConfirm(u.name) : null, danger: ban)) return;
          await repo.setBanned(u.id, ban);
        case 'admin':
          final make = !admins.contains(u.id);
          if (!await confirmDialog(context, title: make ? t.makeAdmin : t.removeAdmin, message: make ? t.makeAdminConfirm(u.name) : null)) return;
          await repo.setAdmin(u.id, make, me);
        case 'ads':
          context.push('/seller/${u.id}');
          return;
      }
      if (context.mounted) context.toast(t.saved);
    } catch (_) {
      if (context.mounted) context.toast(t.somethingWentWrong, error: true);
    }
  }
}

class _UserDetails extends ConsumerWidget {
  const _UserDetails({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return AlertDialog(
      title: Row(children: [Avatar(name: user.name, url: user.photoUrl), const SizedBox(width: 12), Expanded(child: Text(user.name))]),
      content: FutureBuilder<Map<String, dynamic>?>(
        future: ref.read(userRepoProvider).getPrivate(user.id),
        builder: (_, snap) {
          final d = snap.data;
          Widget row(String k, String v) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 110, child: Text(k, style: TextStyle(color: context.colors.outline))),
                  Expanded(child: SelectableText(v.isEmpty ? '-' : v)),
                ]),
              );
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            row(t.email, (d?['email'] ?? '') as String),
            row(t.phone, (d?['phone'] ?? '') as String),
            row(t.city, user.city),
            row(t.memberSinceLabel, formatDate(user.createdAt, context.locale)),
            row(t.status, user.isBanned ? t.banned : t.statusActive),
            row('UID', user.id),
          ]);
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.close))],
    );
  }
}
