import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/listing.dart';

class ChatRepository {
  ChatRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  Stream<List<Chat>> watchMyChats(String uid) => _chats
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(Chat.fromDoc).toList());

  Stream<Chat?> watchChat(String id) => _chats.doc(id).snapshots().map((d) => d.exists ? Chat.fromDoc(d) : null);

  Stream<List<Message>> watchMessages(String chatId, {int limit = 200}) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Message.fromDoc).toList());

  /// Opens (or creates) the buyer↔seller conversation for a listing.
  Future<String> openChat({required Listing listing, required String buyerId, required String buyerName}) async {
    final id = Chat.idFor(listing.id, buyerId);
    final ref = _chats.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [buyerId, listing.ownerId],
        'buyerId': buyerId,
        'sellerId': listing.ownerId,
        'listingId': listing.id,
        'listingTitle': listing.title,
        'listingImage': listing.coverImage ?? '',
        'names': {buyerId: buyerName, listing.ownerId: listing.ownerName},
        'lastMessage': '',
        'lastSenderId': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unread': {buyerId: 0, listing.ownerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Future<void> send({required String chatId, required String senderId, required String otherId, required String text}) {
    final batch = _db.batch();
    final chatRef = _chats.doc(chatId);
    batch.set(chatRef.collection('messages').doc(), {
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unread.$otherId': FieldValue.increment(1),
    });
    return batch.commit();
  }

  Future<void> markRead(String chatId, String uid) => _chats.doc(chatId).update({'unread.$uid': 0});
}
