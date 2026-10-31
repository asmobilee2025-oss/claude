import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/listing.dart';
import '../../widgets/common.dart';

String statusLabel(AppLocalizations t, ListingStatus s) => switch (s) {
      ListingStatus.pending => t.statusPending,
      ListingStatus.active => t.statusActive,
      ListingStatus.rejected => t.statusRejected,
      ListingStatus.sold => t.statusSold,
    };

Color statusColor(BuildContext context, ListingStatus s) => switch (s) {
      ListingStatus.pending => Colors.orange.shade700,
      ListingStatus.active => Colors.green.shade700,
      ListingStatus.rejected => context.colors.error,
      ListingStatus.sold => Colors.blueGrey,
    };

String reportReasonLabel(AppLocalizations t, String r) => switch (r) {
      'spam' => t.reasonSpam,
      'fraud' => t.reasonFraud,
      'prohibited' => t.reasonProhibited,
      'wrongCategory' => t.reasonWrongCategory,
      'offensive' => t.reasonOffensive,
      _ => t.reasonOther,
    };

class ListingStatusBanner extends StatelessWidget {
  const ListingStatusBanner({super.key, required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = listing.status;
    final color = statusColor(context, s);
    final msg = switch (s) {
      ListingStatus.pending => t.pendingExplain,
      ListingStatus.rejected => listing.rejectionReason.isEmpty ? t.rejectedExplain : '${t.rejectedExplain}\n${listing.rejectionReason}',
      ListingStatus.sold => t.soldExplain,
      ListingStatus.active => '',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(statusLabel(t, s), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            if (msg.isNotEmpty) Text(msg),
          ]),
        ),
      ]),
    );
  }
}
