import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../listings/listing_detail_screen.dart' show deleteListingFlow;
import '../listings/listing_status.dart';

final _adminListingsProvider = StreamProvider.autoDispose.family<List<Listing>, String?>(
  (ref, status) => ref.watch(listingRepoProvider).watchByStatus(status, limit: 200),
);

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key, this.initialStatus});
  final String? initialStatus;

  @override
  ConsumerState<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen> {
  late String? _status = widget.initialStatus ?? 'pending';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final filters = <(String?, String)>[
      ('pending', t.statusPending),
      ('active', t.statusActive),
      ('rejected', t.statusRejected),
      ('sold', t.statusSold),
      (null, t.all),
    ];
    final async = ref.watch(_adminListingsProvider(_status));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          decoration: InputDecoration(hintText: t.searchAdsAdmin, prefixIcon: const Icon(Icons.search)),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final f in filters)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(label: Text(f.$2), selected: _status == f.$1, onSelected: (_) => setState(() => _status = f.$1)),
              ),
          ],
        ),
      ),
      Expanded(
        child: AsyncBody(
          value: async,
          data: (all) {
            final items = _q.isEmpty
                ? all
                : all.where((l) => l.title.toLowerCase().contains(_q) || l.ownerName.toLowerCase().contains(_q) || l.id == _q).toList();
            if (items.isEmpty) return EmptyState(icon: Icons.inbox_outlined, title: t.nothingToReview);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AdminListingTile(listing: items[i]),
            );
          },
        ),
      ),
    ]);
  }
}

class _AdminListingTile extends ConsumerWidget {
  const _AdminListingTile({required this.listing});
  final Listing listing;

  Future<void> _run(BuildContext context, Future<void> Function() action, String ok) async {
    try {
      await action();
      if (context.mounted) context.toast(ok);
    } catch (_) {
      if (context.mounted) context.toast(context.t.somethingWentWrong, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final l = listing;
    final repo = ref.read(listingRepoProvider);
    final cat = ref.watch(activeCategoriesProvider).where((c) => c.id == l.categoryId).firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            onTap: () => context.push('/listing/${l.id}'),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 88, height: 88, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(l.coverImage))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusChip(label: statusLabel(t, l.status), color: statusColor(context, l.status)),
                    if (l.featured) StatusChip(label: t.featured, color: Colors.amber.shade800),
                  ]),
                  const SizedBox(height: 4),
                  Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(formatPrice(l.price, l.currency, context.locale), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w800)),
                  Text(
                    '${l.ownerName} · ${cat?.name(context.locale) ?? l.categoryId} · ${cityName(l.city, context.locale)} · ${timeAgo(l.createdAt, t)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: context.colors.outline),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (l.status != ListingStatus.active)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, minimumSize: const Size(0, 40)),
                onPressed: () => _run(context, () => repo.moderate(l.id, ListingStatus.active), t.adApproved),
                icon: const Icon(Icons.check, size: 18),
                label: Text(t.approve),
              ),
            if (l.status != ListingStatus.rejected)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: context.colors.error, minimumSize: const Size(0, 40)),
                onPressed: () async {
                  final reason = await promptDialog(context, title: t.rejectAd, hint: t.rejectReasonHint);
                  if (reason == null || !context.mounted) return;
                  await _run(context, () => repo.moderate(l.id, ListingStatus.rejected, reason: reason), t.adRejected);
                },
                icon: const Icon(Icons.block, size: 18),
                label: Text(t.reject),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _run(context, () => repo.setFeatured(l.id, !l.featured), l.featured ? t.unfeatured : t.markedFeatured),
              icon: Icon(l.featured ? Icons.star : Icons.star_outline, size: 18, color: Colors.amber.shade800),
              label: Text(l.featured ? t.unfeature : t.feature),
            ),
            IconButton(
              tooltip: t.delete,
              onPressed: () => deleteListingFlow(context, ref, l, popAfter: false),
              icon: Icon(Icons.delete_outline, color: context.colors.error),
            ),
          ]),
        ]),
      ),
    );
  }
}
