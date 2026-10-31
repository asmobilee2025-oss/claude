import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../auth/auth_scaffold.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.editProfile)),
      body: AsyncBody(
        value: ref.watch(currentProfileProvider),
        data: (p) => p == null ? const Loading() : _Form(profile: p),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.profile});
  final AppUser profile;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _bio = TextEditingController(text: widget.profile.bio);
  late String? _city = widget.profile.city.isEmpty ? null : widget.profile.city;
  late String _photo = widget.profile.photoUrl;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 85);
    if (f == null) return;
    setState(() => _busy = true);
    try {
      final old = _photo;
      final url = await ref.read(storageServiceProvider).uploadAvatar(widget.profile.id, f);
      setState(() => _photo = url);
      if (old.isNotEmpty) ref.read(storageServiceProvider).deleteByUrl(old);
    } on ImageTooLargeException {
      if (mounted) context.toast(context.t.imageTooLarge, error: true);
    } catch (_) {
      if (mounted) context.toast(context.t.somethingWentWrong, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(userRepoProvider).updateProfile(widget.profile.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
            bio: _bio.text.trim(),
            city: _city ?? '',
            photoUrl: _photo,
          ));
      if (mounted) {
        context.toast(context.t.profileSaved);
        context.pop();
      }
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
          maxWidth: 600,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Stack(children: [
                Avatar(name: _name.text, url: _photo, radius: 48),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: IconButton.filled(onPressed: _busy ? null : _pickAvatar, icon: const Icon(Icons.camera_alt_outlined, size: 18)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              validator: (s) => v.length(s, min: 2, max: 60),
              decoration: InputDecoration(labelText: t.fullName, prefixIcon: const Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (s) => v.phone(s, optional: true),
              decoration: InputDecoration(labelText: t.phone, prefixIcon: const Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: cities.any((c) => c.id == _city) ? _city : null,
              decoration: InputDecoration(labelText: t.city, prefixIcon: const Icon(Icons.place_outlined)),
              items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text(c.name(context.locale)))],
              onChanged: (x) => setState(() => _city = x),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bio,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(labelText: t.bio, alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _save, child: Text(t.saveChanges)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const _ChangePasswordDialog()),
              icon: const Icon(Icons.lock_reset),
              label: Text(t.changePassword),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final v = Validators(t);
    return AlertDialog(
      title: Text(t.changePassword),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PasswordField(controller: _current, label: t.currentPassword, validator: v.required),
          const SizedBox(height: 12),
          PasswordField(controller: _next, label: t.newPassword, validator: v.password),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (!_form.currentState!.validate()) return;
                  setState(() => _busy = true);
                  try {
                    await ref.read(authServiceProvider).changePassword(_current.text, _next.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.toast(t.passwordChanged);
                    }
                  } catch (e) {
                    if (context.mounted) context.toast(authMessage(t, authErrorKey(e)), error: true);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text(t.save),
        ),
      ],
    );
  }
}
