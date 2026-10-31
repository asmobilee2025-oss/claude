import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signIn(_email.text, _password.text);
      // Router redirect sends the user back to `from`.
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
      title: t.welcomeBack,
      subtitle: t.loginSubtitle,
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: v.email,
              decoration: InputDecoration(labelText: t.email, prefixIcon: const Icon(Icons.alternate_email)),
            ),
            const SizedBox(height: 14),
            PasswordField(controller: _password, label: t.password, validator: v.required, onSubmitted: _submit),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text(t.forgotPassword)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(t.login),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(t.noAccount),
              TextButton(
                onPressed: () => context.pushReplacement(
                  Uri(path: '/register', queryParameters: widget.from == null ? null : {'from': widget.from}).toString(),
                ),
                child: Text(t.createAccount),
              ),
            ]),
            TextButton(onPressed: () => context.go('/'), child: Text(t.continueAsGuest)),
          ]),
        ),
      ),
    );
  }
}
