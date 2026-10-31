import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String Function(BuildContext) label;
}

final _dests = <_Dest>[
  _Dest('/admin', Icons.dashboard_outlined, (c) => c.t.overview),
  _Dest('/admin/listings', Icons.fact_check_outlined, (c) => c.t.adsModeration),
  _Dest('/admin/users', Icons.people_outline, (c) => c.t.users),
  _Dest('/admin/categories', Icons.category_outlined, (c) => c.t.categories),
  _Dest('/admin/reports', Icons.flag_outlined, (c) => c.t.reports),
  _Dest('/admin/settings', Icons.tune, (c) => c.t.appSettings),
];

/// Admin layout + access gate. Security rules are the real enforcement; this
/// gate only keeps non-admins from seeing an empty admin UI.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    final i = _dests.lastIndexWhere((d) => d.path == location || (d.path != '/admin' && location.startsWith(d.path)));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final admin = ref.watch(isAdminProvider);
    if (admin.isLoading) return const Scaffold(body: Loading());
    if (admin.value != true) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: t.notAllowed,
          action: FilledButton(onPressed: () => context.go('/'), child: Text(t.backHome)),
        ),
      );
    }

    final title = Text('${t.adminDashboard} · ${_dests[_index].label(context)}');
    final exit = IconButton(tooltip: t.backToApp, onPressed: () => context.go('/'), icon: const Icon(Icons.storefront_outlined));

    if (context.isCompact) {
      return Scaffold(
        appBar: AppBar(title: title, actions: [exit]),
        drawer: NavigationDrawer(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            Navigator.pop(context);
            context.go(_dests[i].path);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
              child: Text(t.adminDashboard, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final d in _dests) NavigationDrawerDestination(icon: Icon(d.icon), label: Text(d.label(context))),
          ],
        ),
        body: child,
      );
    }

    return Scaffold(
      appBar: AppBar(title: title, actions: [exit]),
      body: Row(children: [
        NavigationRail(
          extended: context.isExpanded,
          selectedIndex: _index,
          labelType: context.isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          onDestinationSelected: (i) => context.go(_dests[i].path),
          destinations: [
            for (final d in _dests) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label(context))),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}
