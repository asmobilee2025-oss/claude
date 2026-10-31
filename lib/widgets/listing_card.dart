import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../models/listing.dart';
import '../providers/providers.dart';
import 'common.dart';

class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing, this.trailing});
  final Listing listing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    return Card(
      child: InkWell(
        onTap: () => context.push('/listing/${l.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(fit: StackFit.expand, children: [
              NetImage(l.coverImage),
              if (l.featured)
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: context.colors.tertiary, borderRadius: BorderRadius.circular(6)),
                    child: Text(context.t.featured,
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              PositionedDirectional(top: 4, end: 4, child: FavoriteButton(listingId: l.id, small: true)),
              if (l.images.length > 1)
                PositionedDirectional(
                  bottom: 6,
                  end: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('${l.images.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ]),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                formatPrice(l.price, l.currency, context.locale),
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: context.colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(height: 1.25)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.place_outlined, size: 14, color: context.colors.outline),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${cityName(l.city, context.locale)} · ${timeAgo(l.createdAt, context.t)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: context.colors.outline),
                  ),
                ),
              ]),
              if (trailing != null) ...[const SizedBox(height: 6), trailing!],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Responsive grid used by home, browse, favorites and seller pages.
class ListingGrid extends StatelessWidget {
  const ListingGrid({super.key, required this.items, this.shrinkWrap = false, this.padding = const EdgeInsets.all(12)});
  final List<Listing> items;
  final bool shrinkWrap;
  final EdgeInsets padding;

  static const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 260,
    mainAxisExtent: 290,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: padding,
        gridDelegate: delegate,
        itemCount: items.length,
        itemBuilder: (_, i) => ListingCard(listing: items[i]),
      );
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.listingId, this.small = false});
  final String listingId;
  final bool small;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoriteIdsProvider).value?.contains(listingId) ?? false;
    final btn = IconButton(
      tooltip: context.t.favorites,
      visualDensity: small ? VisualDensity.compact : null,
      style: small ? IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9)) : null,
      icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.redAccent : (small ? Colors.black87 : null), size: small ? 18 : null),
      onPressed: () async {
        final uid = ref.read(currentUidProvider);
        if (uid == null) {
          context.push('/login');
          return;
        }
        try {
          await ref.read(userRepoProvider).setFavorite(uid, listingId, !fav);
        } catch (e) {
          if (context.mounted) context.toast(context.t.somethingWentWrong, error: true);
        }
      },
    );
    return btn;
  }
}
