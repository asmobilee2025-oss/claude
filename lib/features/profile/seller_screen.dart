import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';

class SellerScreen extends ConsumerWidget {
  const SellerScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final profile = ref.watch(userProfileProvider(uid)).value;
    final listings = ref.watch(sellerListingsProvider(uid));
    return Scaffold(
      appBar: AppBar(title: Text(profile?.name ?? t.seller)),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: MaxWidth(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Avatar(name: profile?.name ?? '', url: profile?.photoUrl ?? '', radius: 34),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(profile?.name ?? '', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        if (profile?.createdAt != null)
                          Text(t.memberSince(formatDate(profile!.createdAt, context.locale)), style: TextStyle(color: context.colors.outline)),
                        if ((profile?.city ?? '').isNotEmpty) Text(cityName(profile!.city, context.locale)),
                        if ((profile?.bio ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(profile!.bio)],
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: MaxWidth(child: SectionHeader(t.sellerAds))),
        SliverToBoxAdapter(
          child: MaxWidth(
            child: AsyncBody(
              value: listings,
              data: (items) => items.isEmpty
                  ? EmptyState(icon: Icons.inventory_2_outlined, title: t.noAdsHere)
                  : ListingGrid(items: items, shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24)),
            ),
          ),
        ),
      ]),
    );
  }
}
