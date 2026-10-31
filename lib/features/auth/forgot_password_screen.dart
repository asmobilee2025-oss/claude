import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).sendPasswordReset(_email.text);
    } catch (_) {
      // Do not reveal whether the email exists (prevents account enumeration).
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AuthScaffold(
      title: t.resetPassword,
      subtitle: _sent ? t.resetSent : t.resetSubtitle,
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators(t).email,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: t.email, prefixIcon: const Icon(Icons.alternate_email)),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(_sent ? t.sendAgain : t.sendResetLink)),
        ]),
      ),
    );
  }
}
