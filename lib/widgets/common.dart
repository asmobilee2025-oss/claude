import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  Locale get locale => Localizations.localeOf(this);

  void toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? colors.error : null,
      ));
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.colors.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: context.colors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.error, this.onRetry});
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    debugPrint('ErrorView: $error');
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: context.t.somethingWentWrong,
      subtitle: context.t.tryAgainLater,
      action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: Text(context.t.retry)),
    );
  }
}

/// Renders an [AsyncValue] with consistent loading / error states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        data: data,
        loading: () => const Loading(),
        error: (e, _) => ErrorView(error: e, onRetry: onRetry),
      );
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.icon = Icons.image_outlined});
  final String? url;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: context.colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(icon, color: context.colors.outline, size: 32),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.url = '', this.radius = 22});
  final String name;
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.primaryContainer,
        foregroundImage: url.isEmpty ? null : CachedNetworkImageProvider(url),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * 0.8, color: context.colors.onPrimaryContainer),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirm, bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.t.cancel)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: c.colors.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm ?? c.t.confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> promptDialog(BuildContext context, {required String title, String? hint, int maxLength = 300}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, maxLength: maxLength, maxLines: 3, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(c.t.confirm)),
      ],
    ),
  );
}
