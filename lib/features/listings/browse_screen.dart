import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../services/listing_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, this.categoryId, this.query = ''});
  final String? categoryId;
  final String query;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late ListingFilter _filter = ListingFilter(categoryId: widget.categoryId, query: widget.query);
  late final _search = TextEditingController(text: widget.query);
  final _scroll = ScrollController();
  final List<Listing> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      // Keep fetching until a page yields results (client-side price filter may thin pages).
      var guard = 0;
      while (_hasMore && guard++ < 5) {
        final page = await ref.read(listingRepoProvider).fetchPage(_filter, startAfter: _cursor, limit: AppConstants.pageSize);
        _items.addAll(page.items);
        _cursor = page.lastDoc ?? _cursor;
        _hasMore = page.hasMore;
        if (page.items.isNotEmpty) break;
      }
    } catch (e) {
      _error = e;
      _hasMore = false;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _apply(ListingFilter f) {
    _filter = f;
    _reload();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ListingFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => FilterSheet(initial: _filter),
    );
    if (result != null) _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cats = ref.watch(activeCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.browse),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: MaxWidth(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) => _apply(_filter.copyWith(query: q.trim())),
                      decoration: InputDecoration(
                        hintText: t.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _search.clear();
                                  _apply(_filter.copyWith(query: ''));
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: t.filters,
                    onPressed: _openFilters,
                    icon: Badge(isLabelVisible: _filter.hasExtraFilters, child: const Icon(Icons.tune)),
                  ),
                ]),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(t.all),
                        selected: _filter.categoryId == null,
                        onSelected: (_) => _apply(_filter.copyWith(categoryId: () => null)),
                      ),
                    ),
                    for (final Category c in cats)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          avatar: Icon(c.iconData, size: 18),
                          label: Text(c.name(context.locale)),
                          selected: _filter.categoryId == c.id,
                          onSelected: (_) => _apply(_filter.copyWith(categoryId: () => c.id)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: MaxWidth(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_error != null && _items.isEmpty) return ErrorView(error: _error, onRetry: _reload);
    if (_items.isEmpty && _loading) return const Loading();
    if (_items.isEmpty) {
      return ListView(children: [
        EmptyState(icon: Icons.search_off, title: context.t.noResults, subtitle: context.t.tryDifferentFilters),
      ]);
    }
    return CustomScrollView(controller: _scroll, physics: const AlwaysScrollableScrollPhysics(), slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: ListingGrid.delegate,
          delegate: SliverChildBuilderDelegate((_, i) => ListingCard(listing: _items[i]), childCount: _items.length),
        ),
      ),
      SliverToBoxAdapter(child: _loading ? const Loading() : const SizedBox(height: 32)),
    ]);
  }
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.initial});
  final ListingFilter initial;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _city = widget.initial.city;
  late ListingCondition? _condition = widget.initial.condition;
  late ListingSort _sort = widget.initial.sort;
  late final _min = TextEditingController(text: widget.initial.minPrice?.toStringAsFixed(0) ?? '');
  late final _max = TextEditingController(text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(t.filters, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: () => setState(() {
                _city = null;
                _condition = null;
                _sort = ListingSort.newest;
                _min.clear();
                _max.clear();
              }),
              child: Text(t.reset),
            ),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _city,
            decoration: InputDecoration(labelText: t.city, prefixIcon: const Icon(Icons.place_outlined)),
            items: [
              DropdownMenuItem(value: null, child: Text(t.allCities)),
              for (final c in cities) DropdownMenuItem(value: c.id, child: Text(c.name(context.locale))),
            ],
            onChanged: (v) => setState(() => _city = v),
          ),
          const SizedBox(height: 16),
          Text(t.priceRange, style: context.text.labelLarge),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _min, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.minPrice))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _max, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.maxPrice))),
          ]),
          const SizedBox(height: 16),
          Text(t.condition, style: context.text.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: Text(t.any), selected: _condition == null, onSelected: (_) => setState(() => _condition = null)),
            ChoiceChip(label: Text(t.conditionNew), selected: _condition == ListingCondition.newItem, onSelected: (_) => setState(() => _condition = ListingCondition.newItem)),
            ChoiceChip(label: Text(t.conditionUsed), selected: _condition == ListingCondition.used, onSelected: (_) => setState(() => _condition = ListingCondition.used)),
          ]),
          const SizedBox(height: 16),
          Text(t.sortBy, style: context.text.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: Text(t.sortNewest), selected: _sort == ListingSort.newest, onSelected: (_) => setState(() => _sort = ListingSort.newest)),
            ChoiceChip(label: Text(t.sortPriceLow), selected: _sort == ListingSort.priceLow, onSelected: (_) => setState(() => _sort = ListingSort.priceLow)),
            ChoiceChip(label: Text(t.sortPriceHigh), selected: _sort == ListingSort.priceHigh, onSelected: (_) => setState(() => _sort = ListingSort.priceHigh)),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              widget.initial.copyWith(
                city: () => _city,
                condition: () => _condition,
                sort: _sort,
                minPrice: () => double.tryParse(_min.text.trim()),
                maxPrice: () => double.tryParse(_max.text.trim()),
              ),
            ),
            child: Text(t.showResults),
          ),
        ]),
      ),
    );
  }
}
