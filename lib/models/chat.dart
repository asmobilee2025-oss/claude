import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  const Chat({
    required this.id,
    required this.participants,
    required this.listingId,
    required this.listingTitle,
    this.listingImage = '',
    this.names = const {},
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastMessageAt,
    this.unread = const {},
  });

  final String id;
  final List<String> participants;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final Map<String, String> names;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unread;

  String otherId(String me) => participants.firstWhere((p) => p != me, orElse: () => '');
  String otherName(String me) => names[otherId(me)] ?? '';
  int unreadFor(String me) => unread[me] ?? 0;

  /// Deterministic id: one conversation per (listing, buyer).
  static String idFor(String listingId, String buyerId) => '${listingId}_$buyerId';

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Chat(
      id: doc.id,
      participants: List<String>.from((d['participants'] ?? const []) as List),
      listingId: (d['listingId'] ?? '') as String,
      listingTitle: (d['listingTitle'] ?? '') as String,
      listingImage: (d['listingImage'] ?? '') as String,
      names: Map<String, String>.from((d['names'] ?? const {}) as Map),
      lastMessage: (d['lastMessage'] ?? '') as String,
      lastSenderId: (d['lastSenderId'] ?? '') as String,
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      unread: ((d['unread'] ?? const {}) as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Message(
      id: doc.id,
      senderId: (d['senderId'] ?? '') as String,
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
