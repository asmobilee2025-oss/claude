import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final cats = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredListingsProvider);
    final latest = ref.watch(latestListingsProvider);
    final settings = ref.watch(settingsProvider).value;
    final announcement = settings == null
        ? ''
        : (context.locale.languageCode == 'ar' ? settings.announcementAr : settings.announcementEn);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestListingsProvider);
          ref.invalidate(featuredListingsProvider);
        },
        child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(children: [
              Icon(Icons.storefront, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(t.appName, style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w900)),
            ]),
            actions: [
              IconButton(
                tooltip: t.language,
                onPressed: () => ref.read(localeProvider.notifier).toggle(),
                icon: const Icon(Icons.translate),
              ),
              if (ref.watch(isAdminProvider).value ?? false)
                IconButton(tooltip: t.adminDashboard, onPressed: () => context.push('/admin'), icon: const Icon(Icons.admin_panel_settings_outlined)),
            ],
          ),
          SliverToBoxAdapter(
            child: MaxWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _SearchBox(onSubmit: (q) => context.go(Uri(path: '/browse', queryParameters: {'q': q}).toString())),
                ),
                if (announcement.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Card(
                      color: context.colors.primaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.campaign_outlined, color: context.colors.onPrimaryContainer),
                        title: Text(announcement, style: TextStyle(color: context.colors.onPrimaryContainer)),
                      ),
                    ),
                  ),
                SectionHeader(t.categories, action: t.viewAll, onAction: () => context.go('/browse')),
                cats.when(
                  loading: () => const SizedBox(height: 110, child: Loading()),
                  error: (e, _) => ErrorView(error: e),
                  data: (list) => _CategoryStrip(categories: list.where((c) => c.active).toList()),
                ),
                featured.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          SectionHeader(t.featuredAds),
                          SizedBox(
                            height: 290,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 12),
                              itemBuilder: (_, i) => SizedBox(width: 220, child: ListingCard(listing: items[i])),
                            ),
                          ),
                        ]),
                  orElse: () => const SizedBox.shrink(),
                ),
                SectionHeader(t.latestAds, action: t.viewAll, onAction: () => context.go('/browse')),
                latest.when(
                  loading: () => const Loading(),
                  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(latestListingsProvider)),
                  data: (items) => items.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: t.noAdsYet,
                          subtitle: t.beFirstToPost,
                          action: FilledButton.icon(onPressed: () => context.push('/post'), icon: const Icon(Icons.add), label: Text(t.postAd)),
                        )
                      : ListingGrid(items: items, shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 4, 16, 24)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (q) => widget.onSubmit(q.trim()),
        decoration: InputDecoration(
          hintText: context.t.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => widget.onSubmit(_ctrl.text.trim())),
        ),
      );
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(context.t.noCategories, style: TextStyle(color: context.colors.outline)),
      );
    }
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go(Uri(path: '/browse', queryParameters: {'category': c.id}).toString()),
            child: SizedBox(
              width: 84,
              child: Column(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Icon(c.iconData, color: context.colors.primary, size: 30),
                ),
                const SizedBox(height: 6),
                Text(c.name(context.locale), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
              ]),
            ),
          );
        },
      ),
    );
  }
}
