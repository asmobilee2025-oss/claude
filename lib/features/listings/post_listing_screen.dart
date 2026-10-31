import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../models/listing.dart';
import '../../providers/providers.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';

/// Create a new ad, or edit an existing one when [editId] is set.
class PostListingScreen extends ConsumerWidget {
  const PostListingScreen({super.key, this.editId});
  final String? editId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final user = ref.watch(authStateProvider).value;
    final profile = ref.watch(currentProfileProvider);

    if (user == null) return Scaffold(appBar: AppBar(), body: const Loading());
    if (!user.emailVerified) {
      return Scaffold(appBar: AppBar(title: Text(t.postAd)), body: const VerifyEmailGate());
    }
    if (profile.value?.isBanned ?? false) {
      return Scaffold(
        appBar: AppBar(title: Text(t.postAd)),
        body: EmptyState(icon: Icons.block, title: t.accountBanned),
      );
    }
    if (editId == null) {
      return profile.when(
        loading: () => const Scaffold(body: Loading()),
        error: (e, _) => Scaffold(body: ErrorView(error: e)),
        data: (p) => _ListingForm(existing: null, defaultPhone: p?.phone ?? '', defaultCity: p?.city ?? ''),
      );
    }
    final listing = ref.watch(listingProvider(editId!));
    return listing.when(
      loading: () => const Scaffold(body: Loading()),
      error: (e, _) => Scaffold(appBar: AppBar(), body: ErrorView(error: e)),
      data: (l) {
        if (l == null || l.ownerId != user.uid) {
          return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.lock_outline, title: t.notAllowed));
        }
        return _ListingForm(existing: l, defaultPhone: l.contactPhone, defaultCity: l.city);
      },
    );
  }
}

class VerifyEmailGate extends ConsumerStatefulWidget {
  const VerifyEmailGate({super.key});

  @override
  ConsumerState<VerifyEmailGate> createState() => _VerifyEmailGateState();
}

class _VerifyEmailGateState extends ConsumerState<VerifyEmailGate> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final email = ref.watch(authStateProvider).value?.email ?? '';
    return EmptyState(
      icon: Icons.mark_email_unread_outlined,
      title: t.verifyEmailTitle,
      subtitle: t.verifyEmailBody(email),
      action: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final ok = await ref.read(authServiceProvider).refreshVerification();
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (!ok) context.toast(t.notVerifiedYet, error: true);
                },
          child: Text(t.iVerified),
        ),
        OutlinedButton(
          onPressed: () async {
            try {
              await ref.read(authServiceProvider).resendVerification();
              if (context.mounted) context.toast(t.verificationSent);
            } catch (_) {
              if (context.mounted) context.toast(t.tooManyRequests, error: true);
            }
          },
          child: Text(t.resendEmail),
        ),
      ]),
    );
  }
}

class _ListingForm extends ConsumerStatefulWidget {
  const _ListingForm({required this.existing, required this.defaultPhone, required this.defaultCity});
  final Listing? existing;
  final String defaultPhone;
  final String defaultCity;

  @override
  ConsumerState<_ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends ConsumerState<_ListingForm> {
  final _form = GlobalKey<FormState>();
  late final Listing? e = widget.existing;
  late final _title = TextEditingController(text: e?.title ?? '');
  late final _desc = TextEditingController(text: e?.description ?? '');
  late final _price = TextEditingController(text: e == null ? '' : _fmt(e!.price));
  late final _phone = TextEditingController(text: widget.defaultPhone);
  late String? _category = e?.categoryId;
  late String? _city = widget.defaultCity.isEmpty ? null : widget.defaultCity;
  late ListingCondition _condition = e?.condition ?? ListingCondition.used;
  late bool _negotiable = e?.negotiable ?? false;
  late bool _showPhone = e?.showPhone ?? true;
  late final List<_Img> _images = [for (final u in e?.images ?? const <String>[]) _Img.remote(u)];
  bool _saving = false;
  double _progress = 0;

  static String _fmt(double p) => p % 1 == 0 ? p.toStringAsFixed(0) : p.toString();

  @override
  void dispose() {
    for (final c in [_title, _desc, _price, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final max = ref.read(settingsProvider).value?.maxImages ?? 8;
    final remaining = max - _images.length;
    if (remaining <= 0) {
      context.toast(context.t.maxImagesReached(max), error: true);
      return;
    }
    final files = await ImagePicker().pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 82, limit: remaining);
    if (files.isEmpty) return;
    final added = <_Img>[];
    for (final f in files.take(remaining)) {
      added.add(_Img.local(f, await f.readAsBytes()));
    }
    setState(() => _images.addAll(added));
  }

  Future<void> _submit() async {
    final t = context.t;
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    if (_images.isEmpty) {
      context.toast(t.addAtLeastOnePhoto, error: true);
      return;
    }
    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;
    setState(() {
      _saving = true;
      _progress = 0;
    });
    final storage = ref.read(storageServiceProvider);
    final repo = ref.read(listingRepoProvider);
    final autoApprove = ref.read(settingsProvider).value?.autoApprove ?? false;
    final uploaded = <String>[];
    try {
      final urls = <String>[];
      var done = 0;
      for (final img in _images) {
        if (img.url != null) {
          urls.add(img.url!);
        } else {
          final url = await storage.uploadListingImage(profile.id, img.file!);
          uploaded.add(url);
          urls.add(url);
        }
        done++;
        if (mounted) setState(() => _progress = done / _images.length);
      }
      final base = e ??
          Listing(
            id: '',
            ownerId: profile.id,
            ownerName: profile.name,
            title: '',
            description: '',
            price: 0,
            categoryId: '',
            city: '',
          );
      final listing = base.copyWith(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: double.parse(_price.text.trim()),
        negotiable: _negotiable,
        categoryId: _category,
        city: _city,
        condition: _condition,
        images: urls,
        contactPhone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
        showPhone: _showPhone,
        ownerName: profile.name,
      );
      String id;
      if (e == null) {
        id = repo.newId();
        await repo.create(id, listing, autoApprove: autoApprove);
      } else {
        id = e!.id;
        await repo.update(listing, autoApprove: autoApprove);
        final removed = e!.images.where((u) => !urls.contains(u));
        for (final u in removed) {
          storage.deleteByUrl(u);
        }
      }
      if (!mounted) return;
      context.toast(autoApprove ? t.adPublished : t.adSubmittedForReview);
      context.pushReplacement('/listing/$id');
    } on ImageTooLargeException {
      for (final u in uploaded) {
        storage.deleteByUrl(u);
      }
      if (mounted) context.toast(t.imageTooLarge, error: true);
    } catch (err) {
      debugPrint('post listing failed: $err');
      for (final u in uploaded) {
        storage.deleteByUrl(u);
      }
      if (mounted) context.toast(t.somethingWentWrong, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final v = Validators(t);
    final cats = ref.watch(activeCategoriesProvider);
    final maxImages = ref.watch(settingsProvider).value?.maxImages ?? 8;
    final wide = !context.isCompact;

    final photos = _PhotosSection(
      images: _images,
      max: maxImages,
      onAdd: _saving ? null : _pick,
      onRemove: (i) => setState(() => _images.removeAt(i)),
      onMakeCover: (i) => setState(() => _images.insert(0, _images.removeAt(i))),
    );

    final fields = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<String>(
        initialValue: cats.any((c) => c.id == _category) ? _category : null,
        decoration: InputDecoration(labelText: t.category, prefixIcon: const Icon(Icons.category_outlined)),
        items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name(context.locale)))],
        validator: (x) => x == null ? t.fieldRequired : null,
        onChanged: (x) => setState(() => _category = x),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _title,
        maxLength: AppConstants.titleMax,
        validator: (s) => v.length(s, min: 5, max: AppConstants.titleMax),
        decoration: InputDecoration(labelText: t.adTitle, hintText: t.adTitleHint),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: _desc,
        minLines: 4,
        maxLines: 10,
        maxLength: AppConstants.descriptionMax,
        validator: (s) => v.length(s, min: 10, max: AppConstants.descriptionMax),
        decoration: InputDecoration(labelText: t.description, hintText: t.descriptionHint, alignLabelWithHint: true),
      ),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            validator: v.price,
            decoration: InputDecoration(labelText: t.price, suffixText: AppConstants.currency),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: cities.any((c) => c.id == _city) ? _city : null,
            decoration: InputDecoration(labelText: t.city),
            items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text(c.name(context.locale)))],
            validator: (x) => x == null ? t.fieldRequired : null,
            onChanged: (x) => setState(() => _city = x),
          ),
        ),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t.negotiable),
        value: _negotiable,
        onChanged: (x) => setState(() => _negotiable = x),
      ),
      Text(t.condition, style: context.text.labelLarge),
      const SizedBox(height: 8),
      SegmentedButton<ListingCondition>(
        segments: [
          ButtonSegment(value: ListingCondition.newItem, label: Text(t.conditionNew), icon: const Icon(Icons.fiber_new_outlined)),
          ButtonSegment(value: ListingCondition.used, label: Text(t.conditionUsed), icon: const Icon(Icons.history)),
        ],
        selected: {_condition},
        onSelectionChanged: (s) => setState(() => _condition = s.first),
      ),
      const SizedBox(height: 18),
      TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        validator: (s) => v.phone(s, optional: !_showPhone),
        decoration: InputDecoration(labelText: t.contactPhone, prefixIcon: const Icon(Icons.phone_outlined)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t.showPhoneOnAd),
        subtitle: Text(t.showPhoneOnAdHint),
        value: _showPhone,
        onChanged: (x) => setState(() => _showPhone = x),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(e == null ? t.postAd : t.editAd)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          MaxWidth(
            maxWidth: 1000,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (e != null && !(ref.watch(settingsProvider).value?.autoApprove ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(t.editReReview, style: TextStyle(color: context.colors.outline)),
                ),
              if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 4, child: photos),
                  const SizedBox(width: 24),
                  Expanded(flex: 6, child: fields),
                ])
              else ...[
                photos,
                const SizedBox(height: 20),
                fields,
              ],
              const SizedBox(height: 20),
              if (_saving) ...[
                LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.check),
                label: Text(e == null ? t.publishAd : t.saveChanges),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Img {
  _Img.remote(this.url)
      : file = null,
        bytes = null;
  _Img.local(XFile this.file, Uint8List this.bytes) : url = null;
  final String? url;
  final XFile? file;
  final Uint8List? bytes;
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.images, required this.max, required this.onAdd, required this.onRemove, required this.onMakeCover});
  final List<_Img> images;
  final int max;
  final VoidCallback? onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${t.photos} (${images.length}/$max)', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(t.photosHint, style: context.text.bodySmall?.copyWith(color: context.colors.outline)),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 120, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: images.length < max ? images.length + 1 : images.length,
        itemBuilder: (_, i) {
          if (i == images.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.primary, width: 1.5),
                  color: context.colors.primaryContainer.withValues(alpha: 0.3),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_a_photo_outlined, color: context.colors.primary),
                  const SizedBox(height: 4),
                  Text(t.addPhotos, style: TextStyle(color: context.colors.primary, fontSize: 12)),
                ]),
              ),
            );
          }
          final img = images[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(fit: StackFit.expand, children: [
              img.bytes != null ? Image.memory(img.bytes!, fit: BoxFit.cover) : NetImage(img.url),
              if (i == 0)
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(t.cover, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (i != 0)
                    _MiniBtn(icon: Icons.star_outline, tooltip: t.makeCover, onTap: () => onMakeCover(i)),
                  _MiniBtn(icon: Icons.close, tooltip: t.remove, onTap: () => onRemove(i)),
                ]),
              ),
            ]),
          );
        },
      ),
    ]);
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      );
}
