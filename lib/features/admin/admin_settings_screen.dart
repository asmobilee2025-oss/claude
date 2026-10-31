import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncBody(
        value: ref.watch(settingsProvider),
        data: (s) => _Form(key: ValueKey(s.hashCode), initial: s),
      );
}

class _Form extends ConsumerStatefulWidget {
  const _Form({super.key, required this.initial});
  final AppSettings initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late bool _autoApprove = widget.initial.autoApprove;
  late double _maxImages = widget.initial.maxImages.toDouble();
  late final _phone = TextEditingController(text: widget.initial.supportPhone);
  late final _email = TextEditingController(text: widget.initial.supportEmail);
  late final _annEn = TextEditingController(text: widget.initial.announcementEn);
  late final _annAr = TextEditingController(text: widget.initial.announcementAr);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_phone, _email, _annEn, _annAr]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(catalogRepoProvider).saveSettings(AppSettings(
            autoApprove: _autoApprove,
            maxImages: _maxImages.round(),
            supportPhone: _phone.text,
            supportEmail: _email.text,
            announcementEn: _annEn.text,
            announcementAr: _annAr.text,
          ));
      if (mounted) context.toast(context.t.saved);
    } catch (_) {
      if (mounted) context.toast(context.t.somethingWentWrong, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final v = Validators(t);
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        MaxWidth(
          maxWidth: 720,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
              child: Column(children: [
                SwitchListTile(
                  title: Text(t.autoApprove),
                  subtitle: Text(t.autoApproveHint),
                  value: _autoApprove,
                  onChanged: (x) => setState(() => _autoApprove = x),
                ),
                ListTile(
                  title: Text(t.maxImagesPerAd(_maxImages.round())),
                  subtitle: Slider(value: _maxImages, min: 1, max: 10, divisions: 9, label: '${_maxImages.round()}', onChanged: (x) => setState(() => _maxImages = x)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (s) => v.phone(s, optional: true),
              decoration: InputDecoration(labelText: t.supportWhatsapp, prefixIcon: const Icon(Icons.support_agent)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              validator: (s) => (s ?? '').trim().isEmpty ? null : v.email(s),
              decoration: InputDecoration(labelText: t.supportEmail, prefixIcon: const Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _annEn,
              maxLength: 200,
              decoration: InputDecoration(labelText: t.announcementEnglish, prefixIcon: const Icon(Icons.campaign_outlined)),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _annAr,
              maxLength: 200,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(labelText: t.announcementArabic, prefixIcon: const Icon(Icons.campaign_outlined)),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _save, child: Text(t.saveChanges)),
          ]),
        ),
      ]),
    );
  }
}
