import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../services/catalog_repository.dart';
import '../../widgets/common.dart';

final adminStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) => ref.watch(catalogRepoProvider).stats());

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminStatsProvider.future),
      child: AsyncBody(
        value: ref.watch(adminStatsProvider),
        onRetry: () => ref.invalidate(adminStatsProvider),
        data: (s) {
          final cards = [
            _Stat(t.totalUsers, s.users, Icons.people_outline, Colors.indigo, '/admin/users', sub: '+${s.newUsersWeek} ${t.thisWeek}'),
            _Stat(t.totalAds, s.listings, Icons.inventory_2_outlined, Colors.teal, '/admin/listings', sub: '+${s.newListingsWeek} ${t.thisWeek}'),
            _Stat(t.statusActive, s.active, Icons.check_circle_outline, Colors.green, '/admin/listings?status=active'),
            _Stat(t.pendingReview, s.pending, Icons.hourglass_top, Colors.orange, '/admin/listings?status=pending', highlight: s.pending > 0),
            _Stat(t.openReports, s.openReports, Icons.flag_outlined, Colors.red, '/admin/reports', highlight: s.openReports > 0),
            _Stat(t.statusSold, s.sold, Icons.sell_outlined, Colors.blueGrey, '/admin/listings?status=sold'),
            _Stat(t.statusRejected, s.rejected, Icons.block, Colors.brown, '/admin/listings?status=rejected'),
            _Stat(t.bannedUsers, s.banned, Icons.person_off_outlined, Colors.deepPurple, '/admin/users'),
          ];
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(t.overview, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(t.overviewSubtitle, style: TextStyle(color: context.colors.outline)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: switch (MediaQuery.sizeOf(context).width) { < 600 => 2, < 1000 => 3, _ => 4 },
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [for (final c in cards) _StatCard(stat: c)],
            ),
            const SizedBox(height: 20),
            if (s.listings > 0) _StatusBar(stats: s),
          ]);
        },
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color, this.route, {this.sub, this.highlight = false});
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String route;
  final String? sub;
  final bool highlight;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) => Card(
        shape: stat.highlight
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: stat.color, width: 1.5))
            : null,
        child: InkWell(
          onTap: () => context.go(stat.route),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(stat.icon, color: stat.color, size: 20),
                ),
                const Spacer(),
                if (stat.sub != null)
                  Flexible(child: Text(stat.sub!, overflow: TextOverflow.ellipsis, style: context.text.labelSmall?.copyWith(color: Colors.green.shade700))),
              ]),
              Text('${stat.value}', style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              Text(stat.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colors.outline)),
            ]),
          ),
        ),
      );
}

/// Simple stacked bar showing the share of ads by status.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final parts = [
      (t.statusActive, stats.active, Colors.green),
      (t.statusPending, stats.pending, Colors.orange),
      (t.statusSold, stats.sold, Colors.blueGrey),
      (t.statusRejected, stats.rejected, Colors.brown),
    ];
    final total = parts.fold<int>(0, (s, p) => s + p.$2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.adsByStatus, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(children: [
                for (final p in parts)
                  if (p.$2 > 0) Expanded(flex: p.$2, child: Container(color: p.$3)),
                if (total == 0) Expanded(child: Container(color: context.colors.surfaceContainerHighest)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 8, children: [
            for (final p in parts)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${p.$1}: ${p.$2}${total == 0 ? '' : ' (${(p.$2 * 100 / total).round()}%)'}'),
              ]),
          ]),
        ]),
      ),
    );
  }
}
