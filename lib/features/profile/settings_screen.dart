import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);
    final s = ref.watch(settingsProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        MaxWidth(
          maxWidth: 700,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.language, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('العربية')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (v) => ref.read(localeProvider.notifier).set(Locale(v.first)),
            ),
            const SizedBox(height: 24),
            Text(t.theme, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem), icon: const Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight), icon: const Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
              ],
              selected: {mode},
              onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).set(v.first),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(children: [
                if ((s?.supportPhone ?? '').isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: Text(t.contactSupport),
                    subtitle: Text(s!.supportPhone, textDirection: TextDirection.ltr),
                    onTap: () => launchUrl(Uri.parse('https://wa.me/${s.supportPhone.replaceAll(RegExp(r'[^0-9]'), '')}')),
                  ),
                if ((s?.supportEmail ?? '').isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(t.emailSupport),
                    subtitle: Text(s!.supportEmail),
                    onTap: () => launchUrl(Uri(scheme: 'mailto', path: s.supportEmail)),
                  ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(t.about),
                  subtitle: Text(t.aboutText),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
