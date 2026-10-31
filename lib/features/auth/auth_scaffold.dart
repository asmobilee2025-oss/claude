import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            icon: const Icon(Icons.language),
            label: Text(context.t.otherLanguage),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(18)),
                    child: Icon(Icons.storefront, color: context.colors.onPrimary, size: 34),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 28),
                child,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolves an error key from [authErrorKey] to a localized message.
String authMessage(AppLocalizations t, String key) => switch (key) {
      'invalidEmail' => t.invalidEmail,
      'accountDisabled' => t.accountDisabled,
      'wrongCredentials' => t.wrongCredentials,
      'emailInUse' => t.emailInUse,
      'passwordWeak' => t.passwordWeak,
      'tooManyRequests' => t.tooManyRequests,
      'networkError' => t.networkError,
      _ => t.somethingWentWrong,
    };

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, required this.label, this.validator, this.onSubmitted});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        autofillHints: const [AutofillHints.password],
        onFieldSubmitted: (_) => widget.onSubmitted?.call(),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}
