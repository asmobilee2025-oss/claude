import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../listings/listing_detail_screen.dart' show deleteListingFlow;
import '../listings/listing_status.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final async = ref.watch(myListingsProvider);
    final tabs = <(String, ListingStatus?)>[
      (t.all, null),
      (t.statusActive, ListingStatus.active),
      (t.statusPending, ListingStatus.pending),
      (t.statusSold, ListingStatus.sold),
      (t.statusRejected, ListingStatus.rejected),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.myAds),
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final x in tabs) Tab(text: x.$1)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/post'),
          icon: const Icon(Icons.add),
          label: Text(t.postAd),
        ),
        body: AsyncBody(
          value: async,
          onRetry: () => ref.invalidate(myListingsProvider),
          data: (all) => TabBarView(children: [
            for (final x in tabs)
              _List(items: x.$2 == null ? all : all.where((l) => l.status == x.$2).toList()),
          ]),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.items});
  final List<Listing> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    if (items.isEmpty) {
      return EmptyState(icon: Icons.inventory_2_outlined, title: t.noAdsHere);
    }
    return MaxWidth(
      maxWidth: 900,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final l = items[i];
          return Card(
            child: InkWell(
              onTap: () => context.push('/listing/${l.id}'),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(l.coverImage)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        StatusChip(label: statusLabel(t, l.status), color: statusColor(context, l.status)),
                        if (l.featured) ...[const SizedBox(width: 6), StatusChip(label: t.featured, color: Colors.amber.shade800)],
                      ]),
                      const SizedBox(height: 6),
                      Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(formatPrice(l.price, l.currency, context.locale), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${t.viewsCount(l.views)} · ${timeAgo(l.createdAt, t)}', style: context.text.bodySmall?.copyWith(color: context.colors.outline)),
                      if (l.status == ListingStatus.rejected && l.rejectionReason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${t.reason}: ${l.rejectionReason}', style: TextStyle(color: context.colors.error, fontSize: 12)),
                        ),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'edit':
                          context.push('/edit/${l.id}');
                        case 'sold':
                          await ref.read(listingRepoProvider).markSold(l.id);
                        case 'delete':
                          await deleteListingFlow(context, ref, l, popAfter: false);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(t.edit)),
                      if (l.status == ListingStatus.active) PopupMenuItem(value: 'sold', child: Text(t.markAsSold)),
                      PopupMenuItem(value: 'delete', child: Text(t.delete, style: TextStyle(color: context.colors.error))),
                    ],
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
