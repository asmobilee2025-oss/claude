import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../models/listing.dart';
import '../../models/report.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';
import '../listings/listing_status.dart';

final _reportsProvider = StreamProvider.autoDispose.family<List<Report>, String>(
  (ref, status) => ref.watch(catalogRepoProvider).watchReports(status: status),
);

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _status = 'open';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'open', label: Text(t.reportOpen)),
            ButtonSegment(value: 'resolved', label: Text(t.reportResolved)),
            ButtonSegment(value: 'dismissed', label: Text(t.reportDismissed)),
          ],
          selected: {_status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
      ),
      Expanded(
        child: AsyncBody(
          value: ref.watch(_reportsProvider(_status)),
          data: (items) {
            if (items.isEmpty) return EmptyState(icon: Icons.verified_user_outlined, title: t.noReports);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ReportTile(report: items[i]),
            );
          },
        ),
      ),
    ]);
  }
}

class _ReportTile extends ConsumerWidget {
  const _ReportTile({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final r = report;
    final repo = ref.read(catalogRepoProvider);

    Future<void> run(Future<void> Function() f) async {
      try {
        await f();
        if (context.mounted) context.toast(t.saved);
      } catch (_) {
        if (context.mounted) context.toast(t.somethingWentWrong, error: true);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            StatusChip(label: reportReasonLabel(t, r.reason), color: context.colors.error),
            const Spacer(),
            Text(timeAgo(r.createdAt, t), style: context.text.labelSmall?.copyWith(color: context.colors.outline)),
          ]),
          const SizedBox(height: 8),
          Text(r.listingTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (r.details.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.details)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => context.push('/listing/${r.listingId}'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(t.viewAd),
            ),
            if (r.status == ReportStatus.open) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: context.colors.error, minimumSize: const Size(0, 40)),
                onPressed: () async {
                  final reason = await promptDialog(context, title: t.rejectAd, hint: t.rejectReasonHint);
                  if (reason == null) return;
                  await run(() async {
                    await ref.read(listingRepoProvider).moderate(r.listingId, ListingStatus.rejected, reason: reason);
                    await repo.setReportStatus(r.id, ReportStatus.resolved);
                  });
                },
                icon: const Icon(Icons.block, size: 18),
                label: Text(t.takeDownAd),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => run(() => repo.setReportStatus(r.id, ReportStatus.resolved)),
                child: Text(t.markResolved),
              ),
              TextButton(
                onPressed: () => run(() => repo.setReportStatus(r.id, ReportStatus.dismissed)),
                child: Text(t.dismiss),
              ),
            ] else
              TextButton(onPressed: () => run(() => repo.setReportStatus(r.id, ReportStatus.open)), child: Text(t.reopen)),
          ]),
        ]),
      ),
    );
  }
}
