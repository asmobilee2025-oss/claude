import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.from});
  final String? from;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!_agree) {
      context.toast(context.t.mustAcceptTerms, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
          );
      if (mounted) context.toast(context.t.verificationSent);
    } catch (e) {
      if (mounted) context.toast(authMessage(context.t, authErrorKey(e)), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final v = Validators(t);
    return AuthScaffold(
      title: t.createAccount,
      subtitle: t.registerSubtitle,
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: (s) => v.length(s, min: 2, max: 60),
            decoration: InputDecoration(labelText: t.fullName, prefixIcon: const Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: v.email,
            decoration: InputDecoration(labelText: t.email, prefixIcon: const Icon(Icons.alternate_email)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: v.phone,
            decoration: InputDecoration(labelText: t.phone, hintText: '+9627XXXXXXXX', prefixIcon: const Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 14),
          PasswordField(controller: _password, label: t.password, validator: v.password),
          const SizedBox(height: 14),
          PasswordField(
            controller: _confirm,
            label: t.confirmPassword,
            validator: (s) => s != _password.text ? t.passwordsDontMatch : null,
            onSubmitted: _submit,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _agree,
            onChanged: (x) => setState(() => _agree = x ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(t.acceptTerms, style: context.text.bodySmall),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(t.createAccount),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t.haveAccount),
            TextButton(
              onPressed: () => context.pushReplacement(
                Uri(path: '/login', queryParameters: widget.from == null ? null : {'from': widget.from}).toString(),
              ),
              child: Text(t.login),
            ),
          ]),
        ]),
      ),
    );
  }
}
