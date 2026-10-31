import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { open, resolved, dismissed }

const List<String> reportReasons = ['spam', 'fraud', 'prohibited', 'wrongCategory', 'offensive', 'other'];

class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.listingId,
    required this.listingTitle,
    required this.reason,
    this.details = '',
    this.status = ReportStatus.open,
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String listingId;
  final String listingTitle;
  final String reason;
  final String details;
  final ReportStatus status;
  final DateTime? createdAt;

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Report(
      id: doc.id,
      reporterId: (d['reporterId'] ?? '') as String,
      listingId: (d['listingId'] ?? '') as String,
      listingTitle: (d['listingTitle'] ?? '') as String,
      reason: (d['reason'] ?? 'other') as String,
      details: (d['details'] ?? '') as String,
      status: ReportStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => ReportStatus.open,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
