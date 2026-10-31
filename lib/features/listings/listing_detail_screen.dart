import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import 'listing_status.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  bool _counted = false;

  void _countView(Listing l) {
    if (_counted) return;
    _counted = true;
    final uid = ref.read(currentUidProvider);
    if (uid != null && uid != l.ownerId && l.status == ListingStatus.active) {
      ref.read(listingRepoProvider).incrementViews(l.id).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingProvider(widget.id));
    return Scaffold(
      body: async.when(
        loading: () => const Loading(),
        error: (e, _) => Scaffold(appBar: AppBar(), body: _notFound(context)),
        data: (l) {
          if (l == null) return Scaffold(appBar: AppBar(), body: _notFound(context));
          WidgetsBinding.instance.addPostFrameCallback((_) => _countView(l));
          return _DetailBody(listing: l);
        },
      ),
    );
  }

  Widget _notFound(BuildContext context) => EmptyState(
        icon: Icons.search_off,
        title: context.t.adNotFound,
        action: FilledButton(onPressed: () => context.go('/'), child: Text(context.t.backHome)),
      );
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final t = context.t;
    final uid = ref.watch(currentUidProvider);
    final isOwner = uid == l.ownerId;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final wide = !context.isCompact;

    final gallery = _Gallery(images: l.images);
    final info = _Info(listing: l, isOwner: isOwner);

    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: t.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(ShareParams(
              text: '${l.title} — ${formatPrice(l.price, l.currency, context.locale)}\n${Uri.base.origin}/listing/${l.id}',
            )),
          ),
          FavoriteButton(listingId: l.id),
          if (!isOwner)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'report') _report(context, ref, l);
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'report', child: Text(t.reportAd))],
            ),
        ],
      ),
      SliverToBoxAdapter(
        child: MaxWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (l.status != ListingStatus.active)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ListingStatusBanner(listing: l),
              ),
            if (isAdmin && !isOwner)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/admin/listings'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(t.moderateInAdmin),
                ),
              ),
            if (wide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: gallery),
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: info),
                ]),
              )
            else ...[
              gallery,
              Padding(padding: const EdgeInsets.all(16), child: info),
            ],
            if (!isOwner) _MoreFromSeller(listing: l),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _report(BuildContext context, WidgetRef ref, Listing l) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      context.push('/login');
      return;
    }
    final res = await showDialog<(String, String)>(context: context, builder: (_) => const _ReportDialog());
    if (res == null || !context.mounted) return;
    try {
      await ref.read(catalogRepoProvider).report(
            reporterId: uid,
            listingId: l.id,
            listingTitle: l.title,
            reason: res.$1,
            details: res.$2,
          );
      if (context.mounted) context.toast(context.t.reportSent);
    } catch (_) {
      if (context.mounted) context.toast(context.t.somethingWentWrong, error: true);
    }
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    if (imgs.isEmpty) return const AspectRatio(aspectRatio: 4 / 3, child: NetImage(null));
    return Column(children: [
      AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.isCompact ? 0 : 16),
          child: Stack(children: [
            PageView.builder(
              controller: _page,
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => _FullscreenGallery(images: imgs, initial: i),
                )),
                child: NetImage(imgs[i]),
              ),
            ),
            if (imgs.length > 1)
              PositionedDirectional(
                bottom: 10,
                end: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_index + 1} / ${imgs.length}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white)),
                ),
              ),
          ]),
        ),
      ),
      if (imgs.length > 1)
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: imgs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _page.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: i == _index ? context.colors.primary : Colors.transparent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: NetImage(imgs[i]),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _FullscreenGallery extends StatelessWidget {
  const _FullscreenGallery({required this.images, required this.initial});
  final List<String> images;
  final int initial;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PageView.builder(
          controller: PageController(initialPage: initial),
          itemCount: images.length,
          itemBuilder: (_, i) => InteractiveViewer(child: Center(child: NetImage(images[i], fit: BoxFit.contain))),
        ),
      );
}

class _Info extends ConsumerWidget {
  const _Info({required this.listing, required this.isOwner});
  final Listing listing;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final t = context.t;
    final cats = ref.watch(activeCategoriesProvider);
    final cat = cats.where((c) => c.id == l.categoryId).firstOrNull;

    Widget fact(IconData icon, String label, String value) => Expanded(
          child: Column(children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(height: 4),
            Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.outline)),
            Text(value, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text(
            formatPrice(l.price, l.currency, context.locale),
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: context.colors.primary),
          ),
        ),
        if (l.negotiable) StatusChip(label: t.negotiable, color: context.colors.tertiary),
      ]),
      const SizedBox(height: 6),
      Text(l.title, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        '${cityName(l.city, context.locale)} · ${timeAgo(l.createdAt, t)} · ${t.viewsCount(l.views)}',
        style: context.text.bodySmall?.copyWith(color: context.colors.outline),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(children: [
            fact(Icons.category_outlined, t.category, cat?.name(context.locale) ?? '-'),
            fact(Icons.verified_outlined, t.condition, l.condition == ListingCondition.newItem ? t.conditionNew : t.conditionUsed),
            fact(Icons.place_outlined, t.city, cityName(l.city, context.locale)),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Text(t.description, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      SelectableText(l.description, style: context.text.bodyLarge?.copyWith(height: 1.5)),
      const SizedBox(height: 20),
      if (isOwner) _OwnerActions(listing: l) else ...[
        _SellerCard(listing: l),
        const SizedBox(height: 16),
        if (l.status == ListingStatus.active) _ContactActions(listing: l),
        const SizedBox(height: 16),
        Card(
          color: context.colors.secondaryContainer.withValues(alpha: 0.5),
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(t.safetyTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(t.safetyTips),
          ),
        ),
      ],
    ]);
  }
}

class _SellerCard extends ConsumerWidget {
  const _SellerCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(userProfileProvider(listing.ownerId)).value;
    return Card(
      child: ListTile(
        onTap: () => context.push('/seller/${listing.ownerId}'),
        leading: Avatar(name: seller?.name ?? listing.ownerName, url: seller?.photoUrl ?? ''),
        title: Text(seller?.name ?? listing.ownerName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(seller?.createdAt == null ? context.t.seller : context.t.memberSince(formatDate(seller!.createdAt, context.locale))),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ContactActions extends ConsumerStatefulWidget {
  const _ContactActions({required this.listing});
  final Listing listing;

  @override
  ConsumerState<_ContactActions> createState() => _ContactActionsState();
}

class _ContactActionsState extends ConsumerState<_ContactActions> {
  bool _revealed = false;
  bool _opening = false;

  Future<void> _chat() async {
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) {
      context.push('/login?from=/listing/${widget.listing.id}');
      return;
    }
    setState(() => _opening = true);
    try {
      final id = await ref.read(chatRepoProvider).openChat(listing: widget.listing, buyerId: profile.id, buyerName: profile.name);
      if (mounted) context.push('/chat/$id');
    } catch (_) {
      if (mounted) context.toast(context.t.verifyEmailToContinue, error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final t = context.t;
    final phone = l.contactPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final canCall = l.showPhone && phone.isNotEmpty;
    final loggedIn = ref.watch(currentUidProvider) != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        onPressed: _opening ? null : _chat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(t.chatWithSeller),
      ),
      if (canCall) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.call_outlined),
              label: Text(_revealed ? phone : t.showPhone, textDirection: TextDirection.ltr),
              onPressed: () {
                if (!loggedIn) {
                  context.push('/login?from=/listing/${l.id}');
                } else if (!_revealed) {
                  setState(() => _revealed = true);
                } else {
                  launchUrl(Uri(scheme: 'tel', path: phone));
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.message_outlined, color: Color(0xFF25D366)),
              label: const Text('WhatsApp'),
              onPressed: () {
                if (!loggedIn) {
                  context.push('/login?from=/listing/${l.id}');
                  return;
                }
                final digits = phone.replaceAll('+', '');
                final msg = Uri.encodeComponent('${t.whatsappGreeting} "${l.title}"');
                launchUrl(Uri.parse('https://wa.me/$digits?text=$msg'), mode: LaunchMode.externalApplication);
              },
            ),
          ),
        ]),
      ],
    ]);
  }
}

class _OwnerActions extends ConsumerWidget {
  const _OwnerActions({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final l = listing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t.manageYourAd, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(t.viewsCount(l.views), style: TextStyle(color: context.colors.outline)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(onPressed: () => context.push('/edit/${l.id}'), icon: const Icon(Icons.edit_outlined), label: Text(t.edit)),
            if (l.status == ListingStatus.active)
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (await confirmDialog(context, title: t.markAsSold, message: t.markAsSoldConfirm)) {
                    await ref.read(listingRepoProvider).markSold(l.id);
                  }
                },
                icon: const Icon(Icons.sell_outlined),
                label: Text(t.markAsSold),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: context.colors.error),
              onPressed: () => deleteListingFlow(context, ref, l),
              icon: const Icon(Icons.delete_outline),
              label: Text(t.delete),
            ),
          ]),
        ]),
      ),
    );
  }
}

Future<void> deleteListingFlow(BuildContext context, WidgetRef ref, Listing l, {bool popAfter = true}) async {
  final t = context.t;
  if (!await confirmDialog(context, title: t.deleteAd, message: t.deleteAdConfirm, confirm: t.delete, danger: true)) return;
  try {
    await ref.read(listingRepoProvider).delete(l.id);
    final storage = ref.read(storageServiceProvider);
    for (final url in l.images) {
      storage.deleteByUrl(url);
    }
    if (context.mounted) {
      context.toast(t.adDeleted);
      if (popAfter && context.canPop()) context.pop();
    }
  } catch (_) {
    if (context.mounted) context.toast(t.somethingWentWrong, error: true);
  }
}

class _MoreFromSeller extends ConsumerWidget {
  const _MoreFromSeller({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = (ref.watch(sellerListingsProvider(listing.ownerId)).value ?? const [])
        .where((x) => x.id != listing.id)
        .take(8)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(context.t.moreFromSeller),
      SizedBox(
        height: 290,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 210, child: ListingCard(listing: items[i])),
        ),
      ),
    ]);
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _reason = reportReasons.first;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.reportAd),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v ?? _reason),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final r in reportReasons)
              RadioListTile<String>(value: r, title: Text(reportReasonLabel(t, r)), contentPadding: EdgeInsets.zero),
            TextField(
              controller: _details,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(hintText: t.reportDetailsHint),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, (_reason, _details.text)), child: Text(t.send)),
      ],
    );
  }
}
