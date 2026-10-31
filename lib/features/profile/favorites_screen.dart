import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';

final _favoriteListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider).value ?? <String>{};
  if (ids.isEmpty) return const [];
  return ref.read(listingRepoProvider).byIds(ids.toList());
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.favorites)),
      body: MaxWidth(
        child: AsyncBody(
          value: ref.watch(_favoriteListingsProvider),
          onRetry: () => ref.invalidate(_favoriteListingsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border,
                  title: t.noFavorites,
                  subtitle: t.noFavoritesHint,
                  action: FilledButton(onPressed: () => context.go('/browse'), child: Text(t.browse)),
                )
              : ListingGrid(items: items, padding: const EdgeInsets.all(16)),
        ),
      ),
    );
  }
}
